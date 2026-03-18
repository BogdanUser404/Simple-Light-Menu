import os

#COLORES FOR OUTPUT

GREEN = "\033[92m";
RED = "\033[91m";
YELLOW = "\033[93m";
RESET = "\033[0m";

def print_step(msg):
	print(f"{GREEN}Step: ==>{RESET} {msg}");

def print_error(msg):
	print(f"{RED}Error: ==>{RESET} {msg}");

def print_warning(msg):
	print(f"{YELLOW}Warning: ==>{RESET} {msg}");

print_step("Start building project");
res = os.system("valac --disable-warnings --pkg gtk4 --pkg gio-2.0 --pkg gio-unix-2.0 src/menu.vala src/main.vala -o slde-menu &> /dev/null")

if res != 0:
	print_error("The project failed to build. Do you have Valac and GTK4 installed?");
	print(f"Exit code:{res >> 8}");
	exit(10);

user_input = input("Copy binary to /usr/bin/slde-menu? (y/N): ").strip().lower();
if user_input in ('y', 'yes', 'Y'):
	res = os.system("sudo cp slde-menu /usr/bin/slde-menu");
	if res != 0:
		print_error("Error copying to /usr/bin/slde-menu Do you have permission to access this directory?");
		exit(12);
	print_step("Binary installed to /usr/bin/slde-menu");
else:
	user_bin = os.path.expanduser("~/.local/bin");
	os.makedirs(user_bin, exist_ok=True);
	res = os.system(f"cp slde-menu {user_bin}/slde-menu");
	if res != 0:
		print_error("Error copying to ~/.local/bin do you have this directory?");
		exit(13);
	print_step(f"Binary installed to {user_bin}/slde-menu");

print(f"{GREEN}Build successful {RESET}");
print_warning("Set slde-menu as a menu for your DE manually");