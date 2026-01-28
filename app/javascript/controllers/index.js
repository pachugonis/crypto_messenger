// Import and register all your controllers
import { application } from "controllers/application"

// Eager load all controllers
import ClipboardController from "controllers/clipboard_controller"
import DropdownController from "controllers/dropdown_controller"
import MessageFormController from "controllers/message_form_controller"
import ModalController from "controllers/modal_controller"
import RoomController from "controllers/room_controller"
import ScrollController from "controllers/scroll_controller"
import SearchController from "controllers/search_controller"
import ShareController from "controllers/share_controller"
import ThemeController from "controllers/theme_controller"
import TickerController from "controllers/ticker_controller"
import ToastController from "controllers/toast_controller"
import UploadController from "controllers/upload_controller"

application.register("clipboard", ClipboardController)
application.register("dropdown", DropdownController)
application.register("message-form", MessageFormController)
application.register("modal", ModalController)
application.register("room", RoomController)
application.register("scroll", ScrollController)
application.register("search", SearchController)
application.register("share", ShareController)
application.register("theme", ThemeController)
application.register("ticker", TickerController)
application.register("toast", ToastController)
application.register("upload", UploadController)
