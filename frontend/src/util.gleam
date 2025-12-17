import gleam/dynamic/decode
import gleam/int
import gleam/option
import modem
import rsvp

pub fn not_logged_in() {
  modem.push("/login", option.None, option.None)
}

fn format_rsvp_error(err: rsvp.Error) {
  case err {
    rsvp.BadBody -> "bad body"
    rsvp.BadUrl(url) -> "bad url: " <> url
    rsvp.HttpError(response) ->
      "http error code: " <> int.to_string(response.status)
    rsvp.JsonError(_) -> "response body could not be parsed"
    rsvp.NetworkError -> "network error"
    rsvp.UnhandledResponse(_) -> "unhandled response"
  }
}

pub fn json_handler(
  decoder: decode.Decoder(a),
  happy: fn(a) -> b,
  not_logged_in: b,
  error: fn(String) -> b,
) -> rsvp.Handler(b) {
  rsvp.expect_json(decoder, fn(result) {
    case result {
      Ok(value) -> happy(value)
      Error(err) ->
        case err {
          rsvp.HttpError(resp) ->
            case resp.status {
              401 -> not_logged_in
              _ -> format_rsvp_error(rsvp.HttpError(resp)) |> error
            }
          other -> format_rsvp_error(other) |> error
        }
    }
  })
}
