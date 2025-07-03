// extension.js - Main extension file
const { GObject, St, Clutter, Gio, GLib } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;

const SSHTunnelIndicator = GObject.registerClass(
class SSHTunnelIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'SSH Tunnel Monitor');
        
        // Create a box to hold icon and text
        this._box = new St.BoxLayout({ style_class: 'panel-status-menu-box' });
        
        // Create the panel icon
        this._icon = new St.Icon({
            icon_name: 'network-offline-symbolic',
            style_class: 'system-status-icon'
        });
        this._box.add_child(this._icon);
        
        // Create status text
        this._label = new St.Label({
            text: 'OFF',
            style_class: 'tunnel-status-label',
            y_align: Clutter.ActorAlign.CENTER
        });
        this._box.add_child(this._label);
        
        this.add_child(this._box);
        
        // Create menu items
        this._createMenu();
        
        // Start monitoring
        this._isActive = false;
        this._timeout = null;
        this._sshProcess = null;
        this._startMonitoring();
    }
    
    _createMenu() {
        // Status item
        this._statusItem = new PopupMenu.PopupMenuItem('MongoDB @ linode: Disconnected', {
            reactive: false
        });
        this.menu.addMenuItem(this._statusItem);
        
        // Separator
        this.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

        // Connect/Disconnect Tunnel button
        this._tunnelMenuItem = new PopupMenu.PopupMenuItem('Connect Tunnel');
        this._tunnelMenuItem.connect('activate', () => {
            this._toggleTunnel();
        });
        this.menu.addMenuItem(this._tunnelMenuItem);
        
        // Refresh button
        let refreshItem = new PopupMenu.PopupMenuItem('Refresh Status');
        refreshItem.connect('activate', () => {
            this._checkTunnelStatus();
        });
        this.menu.addMenuItem(refreshItem);
        
        // Settings item (for future use)
        let settingsItem = new PopupMenu.PopupMenuItem('Settings');
        settingsItem.connect('activate', () => {
            // Future: Open settings dialog
            log('SSH Tunnel Monitor: Settings clicked');
        });
        this.menu.addMenuItem(settingsItem);
    }

    _toggleTunnel() {
        if (this._sshProcess) {
            // Disconnect: kill the SSH process
            try {
                this._sshProcess.force_exit();
            } catch (e) {
                log('SSH Tunnel Monitor: Failed to kill SSH process: ' + e.message);
            }
            this._sshProcess = null;
            this._tunnelMenuItem.label.text = 'Connect Tunnel';
            this._updateStatus(false);
        } else {
            // Connect: start the SSH tunnel
            let argv = [
                'ssh', '-N', '-L', '27017:localhost:27017', // can be modified to monitor other services
                'user@remote-host' // update this line for specific target
            ];
            try {
                this._sshProcess = new Gio.Subprocess({
                    argv: argv,
                    flags: Gio.SubprocessFlags.NONE
                });
                this._sshProcess.init(null);
                this._tunnelMenuItem.label.text = 'Disconnect Tunnel';
                this._updateStatus(true);
            } catch (e) {
                log('SSH Tunnel Monitor: Failed to start SSH tunnel: ' + e.message);
                this._sshProcess = null;
            }
        }
    }

    _startMonitoring() {
        // Check status immediately
        this._checkTunnelStatus();
        
        // Set up periodic monitoring (every 5 seconds)
        this._timeout = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 5, () => {
            this._checkTunnelStatus();
            return GLib.SOURCE_CONTINUE;
        });
    }
    
    _checkTunnelStatus() {
        // Check if port is accessible via the tunnel
        let checkCmd = ['nc', '-vz', 'localhost', '27017']; // can be modified to monitor other services
        
        try {
            let proc = Gio.Subprocess.new(
                checkCmd,
                Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
            );
            
            proc.communicate_utf8_async(null, null, (proc, res) => {
                try {
                    let [, stdout, stderr] = proc.communicate_utf8_finish(res);
                    // nc returns 0 if connection succeeds
                    let isActive = proc.get_successful();
                    this._updateStatus(isActive);
                } catch (e) {
                    log(`SSH Tunnel Monitor error: ${e.message}`);
                    this._updateStatus(false);
                }
            });
        } catch (e) {
            log(`SSH Tunnel Monitor error: ${e.message}`);
            this._updateStatus(false);
        }
    }
    
    _updateStatus(isActive) {
        if (this._isActive !== isActive) {
            this._isActive = isActive;
            
            if (isActive) {
                this._icon.icon_name = 'emblem-ok-symbolic';
                this._icon.style_class = 'system-status-icon tunnel-active';
                this._label.text = 'Connected';
                this._label.style_class = 'tunnel-status-label';
                this._statusItem.label.text = 'MongoDB @ linode: Connected';
            } else {
                this._icon.icon_name = 'network-offline-symbolic';
                this._icon.style_class = 'system-status-icon tunnel-inactive';
                this._label.text = 'Disconnected';
                this._label.style_class = 'tunnel-status-label';
                this._statusItem.label.text = 'MongoDB @ linode: Disconnected';
            }
        }
    }
    
    destroy() {
        if (this._timeout) {
            GLib.source_remove(this._timeout);
            this._timeout = null;
        }
        if (this._sshProcess) {
            try {
                this._sshProcess.force_exit();
            } catch (e) {
                log('SSH Tunnel Monitor: Failed to kill SSH process on destroy: ' + e.message);
            }
            this._sshProcess = null;
        }
        super.destroy();
    }
});

class Extension {
    constructor() {
        this._indicator = null;
    }
    
    enable() {
        this._indicator = new SSHTunnelIndicator();
        Main.panel.addToStatusArea('ssh-tunnel-monitor', this._indicator, 0, 'left');
    }
    
    disable() {
        if (this._indicator) {
            this._indicator.destroy();
            this._indicator = null;
        }
    }
}

function init() {
    return new Extension();
}