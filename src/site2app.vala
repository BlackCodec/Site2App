using Gtk;
using WebKit;
using Notify;

namespace Site2App {

	public class Logger {
		
		private static Level current_level = Level.ERROR;
		
		enum Level {
			NONE,
			ERROR,
			INFO,
			DEBUG;
			
			public string string() { return (this.to_string().down().split("level_")[1]).up(); }
		}
		
		public static string level() { return Logger.current_level.string(); }
		
		public static void set_level(string level) {
			switch(level.down()) {
				case "none":
					Logger.current_level = Level.NONE;
					break;
				case "error":
					Logger.current_level = Level.ERROR;
					break;
				case "info":
					Logger.current_level = Level.INFO;
					break;
				case "debug":
					Logger.current_level = Level.DEBUG;
					break;
				default: 
					Logger.print_line(Level.ERROR,"Wrong level: " + level);
					break;
			}
		}
		
		public static void info(string message) { Logger.print_line(Level.INFO," " + message); }
		public static void error(string message, Error e) { Logger.print_line(Level.ERROR,message); Logger.debug(e.message); }
		public static void debug(string message) { Logger.print_line(Level.DEBUG,message); }
		
		private static void print_line(Level level, string message) { 
			if (level <= Logger.current_level)
				print("<%s> [%s] %s\n".printf(Logger.now(),level.string(), message)); 
		}
		
		private static string now() { return (new DateTime.now_local()).to_string(); }
	}

	public class Site2AppWebDataManager: WebsiteDataManager {

		public Site2AppWebDataManager(string base_path) {
			Object(disk_cache_directory: base_path + "/disk/",
				local_storage_directory: base_path + "/data/" ,
				offline_application_cache_directory: base_path + "/cache/",
				indexeddb_directory: base_path + "/database/"
			);
		}
	}

	public class Site2AppWindow : Window {

		private static string DATA_DIR="${HOME}/.local/share/site2app/${session_id}";
		private static string DESKTOP_FILE="${HOME}/.local/share/applications/${session_id}-${app_id}.desktop";

		private string current_data_dir = null;
		private string current_desktop_file = null;
		private string session_id = null;
		private string app_id = null;
		private string site_url = null;
		private bool incognito = false;
		private bool close_to_tray = false;
		private bool save = false;
		private string icon = null;

		private Gtk.StatusIcon tray = null;
		private WebKit.WebView web_view = null;
		private Gtk.Menu menu = null;


		public Site2AppWindow(string session_id, string app_id, string site_url, string icon, bool close_to_tray, bool incognito, bool save) {
			Logger.debug("Entering __new__");
			this.session_id = session_id;
			this.app_id = app_id;
			this.site_url = site_url;
			this.close_to_tray = close_to_tray;
			this.incognito = incognito;
			this.save = save;
			Notify.init (this.app_id);
			// check data structure
			this.current_data_dir = DATA_DIR.replace("~",Environment.get_home_dir())
					.replace("${HOME}",Environment.get_home_dir())
					.replace("${session_id}",this.session_id);
			this.current_desktop_file = DESKTOP_FILE.replace("~",Environment.get_home_dir())
					.replace("${HOME}",Environment.get_home_dir())
					.replace("${app_id}",this.app_id)
					.replace("${session_id}",this.session_id);
			Logger.debug("Set data dir to: " + this.current_data_dir);
			if (!this.incognito) {
				this.create_struct();
			}
			if (icon != "default") {
				this.icon = icon;
			} else {
				this.default_icon();
			}
			this.init();
		}

		private void default_icon() {
			Logger.debug("Entering default_icon");
			string ticon=(this.incognito?"/tmp":this.current_data_dir) + "/" + this.app_id + ".png";
			Logger.debug("Search for icon: " + ticon);
			File file = File.new_for_path(ticon);
			if (!file.query_exists()) {
				Logger.debug("Default icon does not exists, draw it ...");
				// draw text
				Cairo.ImageSurface text_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 256, 256);
				Cairo.Context text_context = new Cairo.Context (text_surface);
				text_context.set_source_rgba(0.91015625,0.9296875,0.95703125,1);
				text_context.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
				text_context.set_font_size (100);
				Cairo.TextExtents extents;
				text_context.text_extents (this.app_id.substring(0,2), out extents);
				double x = 128.0-(extents.width/2 + extents.x_bearing);
				double y = 128.0-(extents.height/2 + extents.y_bearing);
				text_context.move_to (x, y);
				text_context.show_text (this.app_id.substring(0,2));
				text_context.stroke();
				// draw circle
				Cairo.ImageSurface circle_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 256, 256);
				Cairo.Context circle_context = new Cairo.Context (circle_surface);
				circle_context.set_source_rgba(0.0625,0.4453125,0.98046875,0.8);
				circle_context.set_line_width(10.0);
				circle_context.arc(128.0,128.0,76.8,0,2*Math.PI);
				circle_context.fill();
				circle_context.stroke();
				// draw icon
				Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 256, 256);
				Cairo.Context context = new Cairo.Context (surface);
				context.set_operator(Cairo.Operator.OVER);
				context.set_source_surface(circle_context.get_target(),0,1);
				context.paint();
				context.set_operator(Cairo.Operator.OVER);
				context.set_source_surface(text_context.get_target(),0,1);
				context.paint();
				Cairo.Status status_wr = surface.write_to_png(ticon);
				if (status_wr == Cairo.Status.SUCCESS) {
					Logger.info("Draw default icon: " + ticon);
					this.icon = ticon;
				} else {
					Logger.debug("Write png: " + status_wr.to_string());
				}
			} else {
				this.icon = ticon;
			}
			Logger.debug("Exiting default_icon");
		}

		private WebView create_webview() {
			Logger.debug("Entering create_webview");
			WebView web_view = null;
			if (!this.incognito) {
				string c_file = this.current_data_dir + "/cookies.txt";
				WebsiteDataManager data_manager = new Site2AppWebDataManager(this.current_data_dir);
				WebContext context = new WebContext.with_website_data_manager(data_manager);
				web_view = new WebKit.WebView.with_context(context);
				web_view.get_website_data_manager().get_cookie_manager().set_persistent_storage(c_file, CookiePersistentStorage.TEXT);
				web_view.get_website_data_manager().get_cookie_manager().set_accept_policy(CookieAcceptPolicy.NO_THIRD_PARTY);
			} else {
				Logger.info("Create private context ...");
				WebContext context = new WebContext.ephemeral();
				web_view =  new WebKit.WebView.with_context(context);
				web_view.get_website_data_manager().get_cookie_manager().set_accept_policy(CookieAcceptPolicy.NEVER);
			}
			WebKit.Settings settings = web_view.get_settings();
			settings.enable_javascript = true;
			settings.enable_page_cache = true;
			settings.enable_offline_web_application_cache = true;
			settings.load_icons_ignoring_image_load_setting = true;
			settings.auto_load_images = true;
			settings.user_agent = "Site2App";
			List<SecurityOrigin> site_notification = new List<SecurityOrigin>();
			site_notification.append(new SecurityOrigin.for_uri(this.site_url));
			web_view.get_context().init_notification_permissions(site_notification,new List<SecurityOrigin>());
			Logger.debug("Disk cache directory: " + web_view.get_website_data_manager().get_disk_cache_directory());
			Logger.debug("IndexDB directory: " + web_view.get_website_data_manager().get_indexeddb_directory());
			Logger.debug("Local storage: " + web_view.get_website_data_manager().get_local_storage_directory());
			Logger.debug("Offline cache app dir: " + web_view.get_website_data_manager().get_offline_application_cache_directory());
			// menu
			web_view.context_menu.connect((source,menu, event, hit) => {
				menu.remove_all();
				SimpleAction actionReload = new SimpleAction("reload",null);
				actionReload.activate.connect(() => {source.reload();});
				ContextMenuItem itemReload = new WebKit.ContextMenuItem.from_gaction(actionReload,"Reload",null);
				menu.append(itemReload);
				SimpleAction actionReloadCache = new SimpleAction("reload-cache",null);
				actionReloadCache.activate.connect(() => {source.reload_bypass_cache();});
				ContextMenuItem itemReloadCache = new WebKit.ContextMenuItem.from_gaction(actionReloadCache,"Reload (ignore cache)",null);
				menu.append(itemReloadCache);
				SimpleAction actionDeleteCache = new SimpleAction("reload-delete",null);
				actionDeleteCache.activate.connect(() => {
					source.load_plain_text("Delete the cache and reload");
					source.get_context().get_website_data_manager().clear(WebsiteDataTypes.ALL,0,null);
					source.load_uri(this.site_url);
				});
				ContextMenuItem itemDelete = new WebKit.ContextMenuItem.from_gaction(actionDeleteCache,"Delete cache and reload",null);
				menu.append(itemDelete);
				return false;
			});
			Logger.debug("Menu created");
			web_view.show_notification.connect((source,notification) => {
				try {
					Notify.Notification n = new Notify.Notification ("%s - %s".printf(notification.title, this.app_id), notification.body, this.icon);
					n.show ();
				} catch (Error e) {
					error("Error: %s",e.message);
				}
				return true;
			});
			Logger.debug("Notification event connected");
			web_view.load_uri(this.site_url);
			Logger.debug("Exiting create_webview");
			return web_view;
		}

		private Gtk.Box create_box() {
			Logger.debug("Entering create_box");
			Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL,0);
			box.pack_start (this.web_view, true, true, 0);
			Logger.debug("Exiting create_box");
			return box;
		}

		private void create_window(Gtk.Box box) {
			Logger.debug("Entering create_window");
			this.set_title("%s%s".printf(this.app_id,(this.incognito?" - Private":"")));
			this.set_default_size (800, 600);
			this.add(box);
			this.delete_event.connect(() => {
				if (this.close_to_tray) return this.hide_on_delete();
				this.exit();
				return true;
			});
			this.destroy.connect(() => { this.exit(); });
			Logger.debug("Exiting create_window");
		}

		private void init() {
			Logger.debug("Entering init");
			// Create WebView
			this.web_view = this.create_webview();
			this.web_view.show_all();
			// Create Container
			Gtk.Box box = this.create_box();
			box.show_all();
			// Create window
			this.create_window(box);
			// create tray
			this.create_tray();
			this.set_icon_from_file(this.icon);
			this.show_all();
			this.save_file();
			Logger.debug("Exiting init");
		}

		private Gtk.Menu create_menu() {
			Logger.debug("Entering create_menu");
			this.menu = new Gtk.Menu();
			Logger.debug("Append option show to tray menu");
			Gtk.MenuItem menuItem = new Gtk.MenuItem.with_label("Show");
			menuItem.activate.connect(() => { this.from_tray(); });
			menu.append(menuItem);
			Logger.debug("Append option hide to tray menu");
			menuItem = new Gtk.MenuItem.with_label("Hide");
			menuItem.activate.connect(() => { this.to_tray(); });
			menu.append(menuItem);
			Logger.debug("Append option quit to tray menu");
			menuItem = new Gtk.MenuItem.with_label("Quit");
			menuItem.activate.connect(() => { this.exit(); });
			menu.append(menuItem);
			menu.show_all();
			Logger.debug("Exiting create_menu");
			return menu;
		}

		private void create_tray() {
			Logger.debug("Entering create_tray");
			this.tray = new StatusIcon.from_file(this.icon);
			this.tray.set_tooltip_text(this.app_id);
			this.tray.set_visible(true);
			this.tray.activate.connect(() => {
				Logger.debug("Current status: " + (this.is_visible()?"visible":"hidden"));
				if (this.is_visible()) this.to_tray();
				else this.from_tray();
			});
			this.create_menu();
			this.tray.popup_menu.connect(() => { this.menu.popup_at_pointer(); });
			Logger.debug("Exiting create_tray");
		}

		public void to_tray() { this.hide(); }
		public void from_tray() { this.show_all(); }

		public void exit() { Gtk.main_quit(); }

		private void create_struct() {
			Logger.debug("Entering create_struct");
			try {
				File folder = File.new_for_path(this.current_data_dir + "/");
				if (!folder.query_exists()) {
					Logger.debug("Create folder: " + folder.get_uri());
					folder.make_directory_with_parents();
				}
				folder = File.new_for_path(this.current_data_dir+"/data/");
				if (!folder.query_exists()) {
					Logger.debug("Create folder: " + folder.get_uri());
					folder.make_directory_with_parents();
				}
				folder = File.new_for_path(this.current_data_dir+"/disk/");
				if (!folder.query_exists()) {
					Logger.debug("Create folder: " + folder.get_uri());
					folder.make_directory_with_parents();
				}
				folder = File.new_for_path(this.current_data_dir+"/cache/");
				if (!folder.query_exists()) {
					Logger.debug("Create folder: " + folder.get_uri());
					folder.make_directory_with_parents();
				}
				folder = File.new_for_path(this.current_data_dir+"/database/");
				if (!folder.query_exists()) {
					Logger.debug("Create folder: " + folder.get_uri());
					folder.make_directory_with_parents();
				}
			} catch (Error e) {
				Logger.error("Error creating data structure for " + this.current_data_dir, e);
				error("Error creating data structure for %s", this.current_data_dir);
			} finally {
				Logger.debug("Exiting create_struct");
			}
		}
		
		private void save_file() {
			File file = File.new_for_path(this.current_desktop_file);
			if (!this.incognito && this.save && !file.query_exists()) {
				Logger.debug("Entering save_file");
				try {
					string name = this.app_id + " - " + this.session_id;
					string file_content = "[Desktop Entry]\n" +
						"Type=Application\n" + 
						"Encoding=UTF-8\n" +
						"Version=1.0\n" + 
						"Name="+name+"\n" +
						"GenericName=" + name +"\n" +
						"Comment=Site2App " + name + "\n" +
						"Icon="+this.icon+"\n" + 
						"Exec=site2app --session=" + this.session_id +
							" --app='" + this.app_id + "'" +
							" --appurl=" + this.site_url + 
							" --icon=" + this.icon +"\n" +
						"Terminal=false\n" +
						"Categories=GTK;GNOME;Network;\n" +
						"Keywords=web;" + this.app_id +";\n";
					FileOutputStream os = file.create (FileCreateFlags.NONE);
					os.write(file_content.data);
					Logger.info("Saved desktop file: " + name);
				} catch (Error e) {
					Logger.error("Unable to save desktop file",e);
				} finally {
					Logger.debug("Exiting save_file");
				}
			}
		}

		public static void print_help() {
			print("Site2App help\n\n");
			print("Usage: site2app \n");
			print("  [--session=<session_name>]\n\t optional, set a session name, application with same session share the data folder (default value: default)\n");
			print("  --app=<application_name>\n\t required, the application name to use for window and for notifications\n");
			print("  --appurl=<application_url>\n\t required, the url of site that must be showed\n");
			print("  [--tray]\n\t optional, show an icon in system tray (default: false)\n");
			print("  [--icon=<icon_path>]\n\t optional, use the specified icon, if not specified the program draw a custom icon\n");
			print("  [--level=none|error|info|debug]\n\t optional, set logger error level (default value: error)\n");
			print("  [--private]\n\t optional, create a private instance, no datas are stored (default: false)\n");
			print("  [--save]\n\t optional, create desktop file for menu (default: false, if private is set to true this flag is ignored)\n");
			print("  [--help]\n\t print this message and exit\n");
			print("\n\n");
			print("Every time you execute the program with the --save flag enabled it creates a desktop file if it does not exists with category Network\n");
			print("in your ${HOME}/.local/share/applications folder for each application.\n");
			print("If you use the same application name with different session you will have two different desktop files.\n");
		}

		public static int main (string[] args) {
			Gtk.init (ref args);
			string session_id = "default";
			string app_id = null;
			string site_url = null;
			string icon = "default";
			bool incognito = false;
			bool save = false;
			bool to_tray = false;
			for(int i = 0; i < args.length; i++) {
				Logger.debug("Param %d: %s".printf(i ,args[i]));
				if (args[i].has_prefix("--session="))
					session_id = args[i].replace("--session=","").strip();
				if (args[i].has_prefix("--app="))
					app_id = args[i].replace("--app=","").strip();
				if (args[i].has_prefix("--appurl="))
					site_url = args[i].replace("--appurl=","").strip();
				if (args[i].has_prefix("--private"))
					incognito=true;
				if (args[i].has_prefix("--tray"))
					to_tray=true;
				if (args[i].has_prefix("--level="))
					Logger.set_level(args[i].replace("--level=","").strip());
				if (args[i].has_prefix("--icon="))
					icon = args[i].replace("--icon=","").strip();
				if (args[i].has_prefix("--save"))
					save=true;
				if (args[i].has_prefix("--help") || args[i].has_prefix("-h")) {
					print_help();
					return 0;
				}				

			}
			Site2AppWindow app = new Site2AppWindow(session_id,app_id, site_url, icon, to_tray, incognito, save);
			Gtk.main ();
			return 0;
		}
	}
}
