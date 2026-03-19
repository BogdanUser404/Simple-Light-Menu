/*
Simple Light Menu.
(C) Bogdan Yachmenev 2026
License:
GnuGPL 2.0 or later
*/
namespace SLDE {
	using Gtk;
	using GLib;

	public class SLDEMenuApp : Gtk.Application {
		public SLDEMenuApp () {
			Object (
				application_id: "org.slde.menu",
				flags: ApplicationFlags.DEFAULT_FLAGS
			);
		}

		protected override void activate () {
			var win = new Gtk.ApplicationWindow (this);
			win.set_default_size (700, 500);
			win.title = "SLDE Menu";

			ensure_config_exists ();
			load_styles ();

			var menu_widget = new AppMenuWidget ();
			win.set_child (menu_widget);
			win.decorated = false;

			// Check window state every 100 ms
			Timeout.add (100, () => {
				// If window exists and has BACKDROP flag (inactive)
				if (win != null && (win.get_state_flags () & StateFlags.BACKDROP) != 0) {
					win.close ();
					return Source.REMOVE;
				}
				return Source.CONTINUE;
			});

			win.present ();
		}

		private void ensure_config_exists () {
			string path = Path.build_filename (Environment.get_user_config_dir (), "SLDE-menu");
			if (!FileUtils.test (path, FileTest.IS_DIR)) {
				DirUtils.create_with_parents (path, 0755);
			}
		}

		private void load_styles () {
			var provider = new CssProvider ();
			string css_path = Path.build_filename (Environment.get_user_config_dir (), "SLDE-menu", "style.css");

			if (FileUtils.test (css_path, FileTest.EXISTS)) {
				try {
					provider.load_from_path (css_path);
					Gtk.StyleContext.add_provider_for_display (
						Gdk.Display.get_default (),
						provider,
						Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
					);
				} catch (Error e) {
					warning ("Failed to load styles: %s", e.message);
				}
			}
		}

		public static int main (string[] args) {
			return new SLDEMenuApp ().run (args);
		}
	}
}
