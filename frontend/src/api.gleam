import gleam/dynamic/decode
import gleam/http/response
import gleam/int
import gleam/json
import gleam/pair
import middle/token
import middle/user
import rsvp

fn decode_result(decoder) {
  let ok_decoder = decode.map(decoder, Ok)

  let err_decoder = {
    use msg <- decode.field("error", decode.string)
    decode.success(Error(msg))
  }

  decode.one_of(ok_decoder, [err_decoder])
}

fn rsvp_error_to_error(err: rsvp.Error(a)) {
  case err {
    rsvp.BadBody -> Error("ill formed response body")
    rsvp.BadUrl(url) -> Error("ill formed url: '" <> url <> "'")
    rsvp.HttpError(resp) -> {
      let response.Response(status:, ..) = resp
      case status {
        500 -> "Internal Server Error"
        400 -> "Bad Request"
        401 -> "Unauthorized"
        _ -> "Something went wrong! (" <> int.to_string(status) <> ")"
      }
      |> Error
    }
    rsvp.JsonError(_) -> Error("ill formed response body")
    rsvp.NetworkError -> Error("could not connect to the server")
    rsvp.UnhandledResponse(_) -> Error("ill formed response application type")
  }
}

pub fn login(email email, password password, handler handler) {
  let body =
    json.object([
      email
        |> json.string
        |> pair.new("email", _),
      password
        |> json.string
        |> pair.new("password", _),
    ])

  let decoder =
    {
      use token <- decode.field("success", token.decode())
      decode.success(token)
    }
    |> decode_result

  let handler =
    rsvp.expect_json(decoder, fn(result) {
      case result {
        Ok(Ok(token)) -> handler(Ok(token))
        Ok(Error(msg)) -> handler(Error(msg))
        Error(err) -> err |> rsvp_error_to_error |> handler
      }
    })

  rsvp.post("/api/login", body, handler)
}

pub fn register(
  user user,
  password password,
  password_repeat password_repeat,
  handler handler,
) {
  let body =
    [
      user
        |> user.to_json
        |> pair.new("user", _),
      password
        |> json.string
        |> pair.new("password", _),
      password_repeat
        |> json.string
        |> pair.new("password_repeat", _),
    ]
    |> json.object()

  let decoder =
    {
      use token <- decode.field("success", token.decode())
      decode.success(token)
    }
    |> decode_result

  let handler =
    rsvp.expect_json(decoder, fn(result) {
      case result {
        Ok(x) -> handler(x)
        Error(err) -> err |> rsvp_error_to_error() |> handler()
      }
    })

  rsvp.post("/api/register", body, handler)
}
