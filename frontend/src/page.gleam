import page/login
import page/not_found
import page/register

pub type Page {
  Login(login.Model)
  NotFound(not_found.Model)
  Register(register.Model)
}
