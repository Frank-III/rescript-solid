open Ppxlib

open Ast_builder.Default

let has_attr name attrs =
  List.exists (fun (attr : attribute) -> String.equal attr.attr_name.txt name) attrs

let remove_attr name attrs =
  List.filter (fun (attr : attribute) -> not (String.equal attr.attr_name.txt name)) attrs

let enable_defer_rewrite =
  match Sys.getenv_opt "RESCRIPT_SHOW_PPX_NATIVE_DEFER" with
  | Some ("1" | "true" | "TRUE" | "yes" | "on") -> true
  | _ -> false

let enable_defer_jsx_rewrite =
  match Sys.getenv_opt "RESCRIPT_SHOW_PPX_NATIVE_DEFER_JSX" with
  | Some ("1" | "true" | "TRUE" | "yes" | "on") -> true
  | _ -> false

let lident ~loc txt =
  { loc; txt = Longident.parse txt }

let unit_pat ~loc = ppat_construct ~loc (lident ~loc "()") None

let res_arity_attr ~loc arity =
  attribute
    ~loc
    ~name:{ loc; txt = "res.arity" }
    ~payload:(PStr [ pstr_eval ~loc (eint ~loc arity) [] ])

let mark_uncurried ~loc arity fn_expr =
  let wrapped = pexp_construct ~loc (lident ~loc "Function$") (Some fn_expr) in
  { wrapped with pexp_attributes = res_arity_attr ~loc arity :: wrapped.pexp_attributes }

let rewrite_defer expr =
  let loc = expr.pexp_loc in
  let thunk = pexp_fun ~loc Nolabel None (unit_pat ~loc) expr in
  let thunk = mark_uncurried ~loc 1 thunk in
  let call = pexp_ident ~loc (lident ~loc "SolidJSX.ppxDefer") in
  pexp_apply ~loc call [ (Nolabel, thunk) ]

let remove_defer_attr expr =
  {
    expr with
    pexp_attributes = remove_attr "defer" expr.pexp_attributes;
  }

let normalize_defer_for_rewrite expr =
  {
    expr with
    pexp_attributes = expr.pexp_attributes |> remove_attr "defer" |> remove_attr "res.braces";
  }

let rec is_jsx_ident = function
  | Longident.Lident txt ->
    String.equal txt "jsx"
    || String.equal txt "jsxs"
    || String.ends_with ~suffix:".jsx" txt
    || String.ends_with ~suffix:".jsxs" txt
  | Longident.Ldot (_, ("jsx" | "jsxs")) -> true
  | Longident.Ldot (prefix, _) -> is_jsx_ident prefix
  | _ -> false

let is_jsx_expr expr =
  match expr.pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt; _ }; _ }, _) -> is_jsx_ident txt
  | _ -> false

let expr_contains_jsx expr =
  let found = ref false in
  let visitor =
    object
      inherit Ast_traverse.iter as super

      method! expression expr =
        if has_attr "JSX" expr.pexp_attributes || is_jsx_expr expr then found := true;
        if not !found then super#expression expr
    end
  in
  visitor#expression expr;
  !found

let is_some_pattern pattern =
  match pattern.ppat_desc with
  | Ppat_construct ({ txt = Lident "Some"; _ }, Some _) -> true
  | _ -> false

let is_none_or_wild pattern =
  match pattern.ppat_desc with
  | Ppat_construct ({ txt = Lident "None"; _ }, None) -> true
  | Ppat_any -> true
  | _ -> false

let is_true_pattern pattern =
  match pattern.ppat_desc with
  | Ppat_construct ({ txt = Lident "true"; _ }, None) -> true
  | _ -> false

let is_false_or_wild pattern =
  match pattern.ppat_desc with
  | Ppat_construct ({ txt = Lident "false"; _ }, None) -> true
  | Ppat_any -> true
  | _ -> false

let rewrite_show expr =
  match expr.pexp_desc with
  | Pexp_match (scrutinee, [ case1; case2 ])
    when Option.is_none case1.pc_guard && Option.is_none case2.pc_guard ->
    let normalized_match some_lhs some_rhs fallback_rhs =
      {
        expr with
        pexp_desc =
          Pexp_match
            ( scrutinee,
              [
                { pc_lhs = some_lhs; pc_guard = None; pc_rhs = some_rhs };
                { pc_lhs = { some_lhs with ppat_desc = Ppat_any }; pc_guard = None; pc_rhs = fallback_rhs };
              ] );
      }
    in
    (match (is_some_pattern case1.pc_lhs, is_some_pattern case2.pc_lhs) with
    | (true, false) when is_none_or_wild case2.pc_lhs ->
      normalized_match case1.pc_lhs case1.pc_rhs case2.pc_rhs
    | (false, true) when is_none_or_wild case1.pc_lhs ->
      normalized_match case2.pc_lhs case2.pc_rhs case1.pc_rhs
    | _ -> (
      match (is_true_pattern case1.pc_lhs, is_true_pattern case2.pc_lhs) with
      | (true, false) when is_false_or_wild case2.pc_lhs ->
        normalized_match case1.pc_lhs case1.pc_rhs case2.pc_rhs
      | (false, true) when is_false_or_wild case1.pc_lhs ->
        normalized_match case2.pc_lhs case2.pc_rhs case1.pc_rhs
      | _ -> expr))
  | _ -> expr

class mapper =
  object
    inherit Ast_traverse.map as super

    method! expression expr =
      let expr = super#expression expr in
      let attrs = expr.pexp_attributes in
      if has_attr "defer" attrs then (
        let pass_through = remove_defer_attr expr in
        if
          enable_defer_rewrite
          && (enable_defer_jsx_rewrite || not (expr_contains_jsx pass_through))
        then
          pass_through |> normalize_defer_for_rewrite |> rewrite_defer
        else pass_through)
      else if has_attr "show" attrs then
        let expr = { expr with pexp_attributes = remove_attr "show" attrs } in
        rewrite_show expr
      else
        expr
  end

let () =
  Driver.register_transformation
    ~impl:(fun structure ->
      let mapper = new mapper in
      mapper#structure structure)
    "rescript-show-ppx-native"

let () = Driver.standalone ()
