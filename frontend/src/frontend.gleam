import lustre
import page/login
import page/tag
import page/user_overview
import router

pub fn main() {
  let assert Ok(_) = login.register()
  let assert Ok(_) = user_overview.register()
  let assert Ok(_) = tag.register()

  let application = lustre.application(router.init, router.update, router.view)
  let assert Ok(_) = lustre.start(application, "#app", Nil)
}
