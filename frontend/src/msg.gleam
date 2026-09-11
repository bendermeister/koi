import page/login
import page/not_found
import page/register
import route

pub type Msg {
  Login(login.Msg)
  ClientLoadedRoute(route: route.Route)
  Register(register.Msg)
  NotFound(not_found.Msg)
}
