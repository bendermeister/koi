import page/login
import route

pub type Msg {
  Login(login.Msg)
  SignUp
  ClientLoadedRoute(route: route.Route)
}
