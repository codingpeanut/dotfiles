import * as Bluetooth from 'resource:///org/gnome/shell/ui/status/bluetooth.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

export default class HideBluetoothIndicatorExtension extends Extension {
    enable() {
        this._originalSync = Bluetooth.Indicator.prototype._sync;
        Bluetooth.Indicator.prototype._sync = function () {
            this._originalSync.call(this);
            this._indicator.visible = false;
        };

        // The panel indicator is created before extensions are loaded, so
        // re-sync once to hide an icon that is already visible this session.
        Main.panel?._bluetooth?._sync?.();
    }

    disable() {
        if (this._originalSync) {
            Bluetooth.Indicator.prototype._sync = this._originalSync;
            this._originalSync = null;
        }

        // Re-sync with the original method to restore the icon state.
        Main.panel?._bluetooth?._sync?.();
    }
}
