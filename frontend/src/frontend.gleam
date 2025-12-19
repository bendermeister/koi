import lustre
import page/inbox
import page/login
import router

pub fn main() {
  let assert Ok(_) = login.register()
  let assert Ok(_) = inbox.register()

  let app = lustre.application(router.init, router.update, router.view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
}
