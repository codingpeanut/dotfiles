import * as Bluetooth from 'resource:///org/gnome/shell/ui/status/bluetooth.js';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

export default class HideBluetoothIndicatorExtension extends Extension {
    enable() {
        this._originalSync = Bluetooth.Indicator.prototype._sync;
        Bluetooth.Indicator.prototype._sync = function () {
            this._indicator.visible = false;
        };
    }

    disable() {
        if (this._originalSync)
            Bluetooth.Indicator.prototype._sync = this._originalSync;
        this._originalSync = null;
    }
}
