pragma Singleton
import Quickshell
import qs.services
import qs.modules.common

Singleton {
    id: root

    function closeAllWindows() {
        // Sólo tiene sentido en sesiones Hyprland; en Niri no hay HyprlandData
        if (!CompositorService.isHyprland)
            return;

        HyprlandData.windowList.map(w => w.pid).forEach(pid => {
            Quickshell.execDetached(["kill", pid]);
        });
    }

    function lock() {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend() {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function logout() {
        // En Niri salimos limpiamente vía NiriService, en Hyprland matamos la sesión
        if (CompositorService.isNiri) {
            NiriService.quit();
            return;
        }

        closeAllWindows();
        Quickshell.execDetached(["pkill", "-i", "Hyprland"]);
    }

    function launchTaskManager() {
        Quickshell.execDetached(["bash", "-c", `${Config.options.apps.taskManager}`]);
    }

    function hibernate() {
        Quickshell.execDetached(["bash", "-c", `systemctl hibernate || loginctl hibernate`]);
    }

    function poweroff() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `systemctl poweroff || loginctl poweroff`]);
    }

    function reboot() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `reboot || loginctl reboot`]);
    }

    function rebootToFirmware() {
        closeAllWindows();
        Quickshell.execDetached(["bash", "-c", `systemctl reboot --firmware-setup || loginctl reboot --firmware-setup`]);
    }
}
