open Ppxlib

let has_attr name attrs =
  List.exists (fun (attr : attribute) -> String.equal attr.attr_name.txt name) attrs

let remove_attr name attrs =
  List.filter (fun (attr : attribute) -> not (String.equal attr.attr_name.txt name)) attrs

let is_some_pattern pattern =
  match pattern.ppat_desc with
  | Ppat_construct ({ txt = Lident "Some"; _ }, Some _) -> true
  | _ -> false

let is_none_or_wild pattern =
  match pattern.ppat_desc with
  | Ppat_construct ({ txt = Lident "None"; _ }, None) -> true
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
    | _ -> expr)
  | _ -> expr

class mapper =
  object
    inherit Ast_traverse.map as super

    method! expression expr =
      let expr = super#expression expr in
      let attrs = expr.pexp_attributes in
      if has_attr "defer" attrs then
        expr
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
