// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

// Import Stimulus and controllers
import { application } from "controllers/application"
import DropdownController from "controllers/dropdown_controller"
import HandleController from "controllers/handle_controller"
import MessageFormController from "controllers/message_form_controller"
import ModalController from "controllers/modal_controller"
import RoomController from "controllers/room_controller"
import ScrollController from "controllers/scroll_controller"
import SearchController from "controllers/search_controller"
import ShareController from "controllers/share_controller"
import ThemeController from "controllers/theme_controller"
import ToastController from "controllers/toast_controller"
import UploadController from "controllers/upload_controller"

// Register controllers
application.register("dropdown", DropdownController)
application.register("handle", HandleController)
application.register("message-form", MessageFormController)
application.register("modal", ModalController)
application.register("room", RoomController)
application.register("scroll", ScrollController)
application.register("search", SearchController)
application.register("share", ShareController)
application.register("theme", ThemeController)
application.register("toast", ToastController)
application.register("upload", UploadController)
