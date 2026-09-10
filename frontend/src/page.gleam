import page/login

pub type Page {
  Login(login.Model)
  SignUp
  NotFound
}
