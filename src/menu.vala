/*
 * Simple Light Menu
 * (C) 2026 Bogdan Yachmenev <yachmenevbogdan350@gmail.com>
 * 
 * Licensed under GNU GPL v2.0 or later with ETHICAL TERMS:
 * 1. AI TRAINING: Use for training requires disclosure of model weights.
 * 2. MILITARY: Use for military purposes requires full source disclosure.
 * 
 * Distributed WITHOUT ANY WARRANTY. See LICENSE for details.
 */

namespace SLDE {
	using Gtk;
	using GLib;

	public class AppMenuWidget : Gtk.Box {
		private FlowBox grid;
		private ListBox category_list;
		private SearchEntry search_entry;
		private ScrolledWindow scroll;
		private List<AppInfo> all_apps;

		public AppMenuWidget () {
			// Horizontal container [ Left | Right ]
			Object (orientation: Orientation.HORIZONTAL, spacing: 0);

			// 1. Left category panel
			category_list = new ListBox ();
			category_list.width_request = 200; // Fixed width
			category_list.add_css_class ("sidebar");
			category_list.row_selected.connect (on_category_selected);
			
			var cat_scroll = new ScrolledWindow ();
			cat_scroll.set_child (category_list);
			cat_scroll.hscrollbar_policy = PolicyType.NEVER;
			cat_scroll.hexpand = false; // Left panel does not expand
			this.append (cat_scroll);

			// 2. Right part (Search + Grid + Power buttons)
			var right_box = new Box (Orientation.VERTICAL, 10);
			right_box.hexpand = true; // Takes remaining space
			right_box.margin_top = right_box.margin_bottom = 12;
			right_box.margin_start = right_box.margin_end = 12;
			this.append (right_box);

			search_entry = new SearchEntry ();
			search_entry.placeholder_text = "Search apps...";
			search_entry.search_changed.connect (() => { grid.invalidate_filter (); });
			right_box.append (search_entry);

			scroll = new ScrolledWindow ();
			scroll.vexpand = true;
			grid = new FlowBox ();
			grid.max_children_per_line = 6;
			grid.selection_mode = SelectionMode.NONE;
			grid.row_spacing = 15;
			grid.column_spacing = 15;
			grid.set_filter_func (filter_func);
			
			scroll.set_child (grid);
			right_box.append (scroll);

			// --- Power buttons (shutdown, suspend, reboot) ---
			var power_box = new Box (Orientation.HORIZONTAL, 10);
			power_box.homogeneous = true;  // make all buttons same width
			power_box.margin_top = 10;      // spacing from the grid above

			// Shutdown button
			var shutdown_btn = create_power_button ("system-shutdown-symbolic", "Shutdown");
			shutdown_btn.clicked.connect (() => {
				run_systemctl ("poweroff");
			});
			power_box.append (shutdown_btn);

			// Suspend button
			var suspend_btn = create_power_button ("system-suspend-symbolic", "Suspend");
			suspend_btn.clicked.connect (() => {
				run_systemctl ("suspend");
			});
			power_box.append (suspend_btn);

			// Reboot button
			var reboot_btn = create_power_button ("system-reboot-symbolic", "Reboot");
			reboot_btn.clicked.connect (() => {
				run_systemctl ("reboot");
			});
			power_box.append (reboot_btn);

			right_box.append (power_box);
			// -------------------------------------------------

			load_apps_and_categories ();
		}

		// Helper to create a button with icon and tooltip
		private Button create_power_button (string icon_name, string tooltip) {
			var btn = new Button ();
			btn.set_icon_name (icon_name);
			btn.set_tooltip_text (tooltip);
			btn.add_css_class ("power-button");  // optional styling
			return btn;
		}

		// Run systemctl command asynchronously
		private void run_systemctl (string action) {
			try {
				Process.spawn_command_line_async ("systemctl " + action);
			} catch (Error e) {
				stderr.printf ("Failed to run systemctl %s: %s\n", action, e.message);
			}
		}

		private void load_apps_and_categories () {
			all_apps = AppInfo.get_all ();
			all_apps.sort ((a, b) => {
				return a.get_name ().down ().collate (b.get_name ().down ());
			});

			// Register categories
			add_cat ("All applications", null);
			add_cat ("Internet", "Network");
			add_cat ("Graphics", "Graphics");
			add_cat ("Office", "Office");
			add_cat ("Games", "Game");
			add_cat ("Multimedia", "AudioVideo");
			add_cat ("System", "System");
			add_cat ("Development", "Development");
			add_cat ("Utilities", "Utility");

			// Select "All" by default
			var first_row = category_list.get_row_at_index (0);
			if (first_row != null) {
				category_list.select_row (first_row);
				show_category (null);
			}
		}

		private void add_cat (string name, string? filter) {
			var label = new Label (name);
			label.xalign = 0;
			label.margin_start = 15;
			label.margin_top = label.margin_bottom = 12;
			label.set_data<string> ("filter", filter);
			category_list.append (label);
		}

		private void on_category_selected (ListBoxRow? row) {
			if (row == null) return;
			var label = row.get_child () as Label;
			if (label == null) return;
			string? filter = label.get_data<string> ("filter");
			show_category (filter);
		}

		private void show_category (string? filter) {
			Widget? child;
			while ((child = grid.get_first_child ()) != null) {
				grid.remove (child);
			}

			foreach (var app in all_apps) {
				if (!app.should_show ()) continue;

				bool match = false;
				if (filter == null) {
					match = true;
				} else {
					var d_app = app as DesktopAppInfo;
					if (d_app != null) {
						string cats = d_app.get_categories () ?? "";
						if (cats.contains (filter)) match = true;
					}
				}

				if (match) {
					grid.append (create_item (app));
				}
			}
			scroll.get_vadjustment ().set_value (0);
		}

		private Widget create_item (AppInfo app) {
			var btn = new Button ();
			btn.has_frame = false;
			btn.add_css_class ("app-item");
			
			var box = new Box (Orientation.VERTICAL, 6);
			var icon = new Image.from_gicon (app.get_icon ());
			icon.pixel_size = 56;
			
			var label = new Label (app.get_name ());
			label.ellipsize = Pango.EllipsizeMode.END;
			label.max_width_chars = 12;

			box.append (icon);
			box.append (label);
			btn.set_child (box);
			btn.set_data<string> ("name", app.get_name ().down ());

			btn.clicked.connect (() => {
				try {
					app.launch (null, null);
				} catch (Error e) {
					stderr.printf ("Error: %s\n", e.message);
				}
			});
			return btn;
		}

		private bool filter_func (FlowBoxChild child) {
			string text = search_entry.get_text ().down ().strip ();
			if (text == "") return true;
			var btn = child.get_child () as Button;
			if (btn == null) return false;
			string? name = btn.get_data<string> ("name");
			return (name != null) ? name.contains (text) : false;
		}
	}
}
