# Route

```swift
let api = API<Pokemon>()
    .request {
      $0.https
        .host("pokeapi.co")
        .path("api/v2/pokemon/ditto/")
    }
    .responseChain {
      $0.validateHTTPStatus()
        .JSONMapping(Pokemon.self)
        .validate {
          $0.weight > 10
        }
    }

apiClient.send(api) { result in
  switch result {
  case let .success(pokemon):
    // success
  case let .failure(error):
    // fail
  }
}
```
