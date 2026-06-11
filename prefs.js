// ESM preferences (GNOME 45+)
import Adw from 'gi://Adw';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';

import {ExtensionPreferences, gettext as _} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class SysMonPreferences extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();

        window.set_default_size(480, 420);

        const page = new Adw.PreferencesPage();
        const group = new Adw.PreferencesGroup({
            title: _('Display'),
            description: _('Choose which resources appear in the panel and popup.'),
        });

        const intervalRow = new Adw.SpinRow({
            title: _('Refresh interval (seconds)'),
            subtitle: _('Lower values update faster and use slightly more CPU.'),
            adjustment: new Gtk.Adjustment({
                lower: 1,
                upper: 10,
                step_increment: 1,
            }),
        });
        settings.bind('refresh-interval', intervalRow, 'value', Gio.SettingsBindFlags.DEFAULT);
        group.add(intervalRow);

        const toggles = [
            ['monochrome-mode', _('Monochrome mode'), _('Use one neutral color instead of status colors.')],
            ['show-cpu', _('Show CPU'), _('Display processor usage.')],
            ['show-ram', _('Show RAM'), _('Display memory usage.')],
            ['show-gpu', _('Show GPU'), _('Display GPU usage when supported.')],
            ['show-swap', _('Show Swap'), _('Display swap usage.')],
            ['show-network', _('Show Network'), _('Display upload and download speeds.')],
        ];

        for (const [key, label, subtitle] of toggles) {
            const row = new Adw.SwitchRow({title: label, subtitle});
            settings.bind(key, row, 'active', Gio.SettingsBindFlags.DEFAULT);
            group.add(row);
        }

        page.add(group);
        window.add(page);
    }
}
