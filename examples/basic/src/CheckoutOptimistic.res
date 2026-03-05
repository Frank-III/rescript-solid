open Solid

@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@send external toFixed: (float, int) => string = "toFixed"
@get external getInputValue: {..} => string = "value"

type country = [#US | #UK]

type regionalConfig = {
  preferredCourierId: string,
  taxSchemeId: string,
}

type shippingInfo = {
  provider: string,
  price: float,
}

type taxInfo = {
  scheme: string,
  rate: float,
}

type guess = {
  courier: string,
  tax: string,
}

let itemPrice = 100.0

let countryCode = (country: country) =>
  switch country {
  | #US => "US"
  | #UK => "UK"
  }

let countryFromCode = (code: string): country =>
  switch code {
  | "UK" => #UK
  | _ => #US
  }

let delay = ms =>
  Promise.make((resolve, _reject) => {
    let _ = setTimeout(() => resolve(), ms)
  })

let money = value => "$" ++ toFixed(value, 2)

module DB = {
  let userCountry = ref(#US)

  let offlineGuess = (country: country): guess =>
    switch country {
    | #US => {courier: "FEDEX_PRIORITY", tax: "UK_VAT_FINAL"}
    | #UK => {courier: "DHL_EXPRESS", tax: "VAT_GUESSED_WRONG"}
    }

  let configFor = (country: country): regionalConfig =>
    switch country {
    | #US => {preferredCourierId: "FEDEX_PRIORITY", taxSchemeId: "US_SALES_TAX_V2"}
    | #UK => {preferredCourierId: "DHL_EXPRESS", taxSchemeId: "UK_VAT_FINAL"}
    }
}

module Api = {
  let fetchUserCountry = async () => {
    let _ = await delay(300)
    DB.userCountry.contents
  }

  let updateUserCountry = async (country: country) => {
    let _ = await delay(1000)
    DB.userCountry.contents = country
    country
  }

  let fetchRegionalConfig = async (country: country) => {
    let _ = await delay(3000)
    DB.configFor(country)
  }

  let fetchShippingQuote = async courierId => {
    let _ = await delay(1000)
    switch courierId {
    | "FEDEX_PRIORITY" => 15.0
    | _ => 25.0
    }
  }

  let fetchTaxRate = async taxSchemeId => {
    let _ = await delay(700)
    switch taxSchemeId {
    | "UK_VAT_FINAL" | "VAT_GUESSED_WRONG" => 0.2
    | _ => 0.08
    }
  }
}

@jsx.component
let make = () => {
  let (userCountry, _setUserCountry) = createSignalFromAsyncFnWithInitial(() => Api.fetchUserCountry(), #US)
  let (isChangingCountry, setIsChangingCountry) = createSignal(false)
  let (optimisticCountry, setOptimisticCountry) =
    createOptimisticFromFnWithInitial(() => userCountry(), #US)

  let (regionalConfig, _setRegionalConfig) =
    createSignalFromAsyncFnWithInitial(() => Api.fetchRegionalConfig(optimisticCountry()), DB.configFor(#US))

  let (optimisticCourier, setOptimisticCourier) =
    createOptimisticFromFnWithInitial(() => regionalConfig().preferredCourierId, "FEDEX_PRIORITY")
  let (optimisticTaxScheme, setOptimisticTaxScheme) =
    createOptimisticFromFnWithInitial(() => regionalConfig().taxSchemeId, "US_SALES_TAX_V2")

  let (shippingInfo, _setShippingInfo) = createSignalFromAsyncFnWithInitial(async (): shippingInfo => {
    let provider = optimisticCourier()
    let price = await Api.fetchShippingQuote(provider)
    {provider, price}
  }, {provider: "FEDEX_PRIORITY", price: 15.0})

  let (taxInfo, _setTaxInfo) = createSignalFromAsyncFnWithInitial(async (): taxInfo => {
    let scheme = optimisticTaxScheme()
    let rate = await Api.fetchTaxRate(scheme)
    {scheme, rate}
  }, {scheme: "US_SALES_TAX_V2", rate: 0.08})

  let orderTotal = createMemo(() =>
    itemPrice +. itemPrice *. taxInfo().rate +. shippingInfo().price
  )

  let shippingPending = () => isPending(() => shippingInfo())
  let taxPending = () => isPending(() => taxInfo())
  let shippingClass = () => "checkout-breakdown-col " ++ (shippingPending() ? "checkout-faded" : "")
  let taxClass = () =>
    "checkout-breakdown-col checkout-breakdown-tax " ++ (taxPending() ? "checkout-faded" : "")

  createTrackEffect(() => {
    if !isPending(() => userCountry()) {
      setIsChangingCountry(_ => false)
    }
  })

  let handleCountryChange = action((newCountry: country) => {
    let guess = DB.offlineGuess(newCountry)
    setOptimisticCountry(_ => newCountry)
    setOptimisticCourier(_ => guess.courier)
    setOptimisticTaxScheme(_ => guess.tax)

    awaitStep(Api.updateUserCountry(newCountry), _ => {
      refresh(userCountry)
      doneStep()
    })
  })

  <section className="checkout-shell">
      <h1 className="checkout-heading"> {string("Order Checkout")} </h1>

      <div className="checkout-country-row">
        <label className="checkout-country-label"> {string("Shipping To:")} </label>
        <select
          className="checkout-country-select"
          value={countryCode(optimisticCountry())}
          onChange={event => {
            let next = event->JsxEvent.Form.target->getInputValue->countryFromCode
            setIsChangingCountry(_ => true)
            handleCountryChange(next)->ignore
          }}
          disabled={isChangingCountry() || isPending(() => userCountry())}
        >
          <option value="US"> {string("USA")} </option>
          <option value="UK"> {string("UK")} </option>
        </select>
      </div>

      <p className="checkout-item-price"> {string("Item Price: " ++ money(itemPrice))} </p>

      <div className="checkout-breakdown">
        <div className={shippingClass()}>
          <p className="checkout-breakdown-title"> {string("Shipping")} </p>
          <p className="checkout-breakdown-line">
            {string("Provider: ")}
            <b> {string(shippingInfo().provider)} </b>
          </p>
          <p className="checkout-breakdown-line">
            {string("Price: " ++ money(shippingInfo().price))}
          </p>
        </div>
        <div className={taxClass()}>
          <p className="checkout-breakdown-title"> {string("Tax")} </p>
          <p className="checkout-breakdown-line">
            {string("Tax ID: ")}
            <b> {string(taxInfo().scheme)} </b>
          </p>
          <p className="checkout-breakdown-line">
            {string(
              "Tax Rate: " ++
              money(itemPrice *. taxInfo().rate) ++
              " (" ++
              toFixed(taxInfo().rate *. 100.0, 0) ++ "%)",
            )}
          </p>
        </div>
      </div>

      <p className="checkout-total"> {string("Total: " ++ money(orderTotal()))} </p>

      <button className="checkout-pay-button" disabled={isPending(optimisticCountry)}>
        {string(isPending(optimisticCountry) ? "Updating Calculations..." : "Pay Now")}
      </button>
    </section>
}
