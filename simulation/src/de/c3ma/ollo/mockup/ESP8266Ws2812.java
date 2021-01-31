package de.c3ma.ollo.mockup;

import java.io.File;

import javax.swing.SwingUtilities;

import org.luaj.vm2.LuaString;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.ZeroArgFunction;

import de.c3ma.ollo.LuaSimulation;
import de.c3ma.ollo.mockup.ui.WS2812Layout;

/**
 * created at 28.12.2017 - 23:34:04<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * 
 * @author ollo<br />
 */
public class ESP8266Ws2812 extends TwoArgFunction {

	private static WS2812Layout layout = null;

	@Override
	public LuaValue call(LuaValue modname, LuaValue env) {
		env.checkglobals();
		final LuaTable ws2812 = new LuaTable();
		ws2812.set("init", new init());
		ws2812.set("write", new write());
		env.set("ws2812", ws2812);
		env.get("package").get("loaded").set("ws2812", ws2812);
		return ws2812;
	}

	private class init extends ZeroArgFunction {

		@Override
		public LuaValue call() {
			System.out.println("[WS2812] init");
			return LuaValue.valueOf(true);
		}

	}

	private class write extends OneArgFunction {

		@Override
		public LuaValue call(LuaValue arg) {
			if (arg.isstring()) {
				LuaString jstring = arg.checkstring();
				final int length = jstring.rawlen();
				if ((length % 3) == 0) {
					final byte[] array = jstring.m_bytes;
					SwingUtilities.invokeLater(new Runnable() {
						@Override
						public void run() {
							for (int i = 0; i < length; i += 3) {
								if (ESP8266Ws2812.layout != null) {
									int r = array[i + 0]+(Byte.MIN_VALUE*-1);
									int b = array[i + 1]+(Byte.MIN_VALUE*-1);
									int g = array[i + 2]+(Byte.MIN_VALUE*-1);
									ESP8266Ws2812.layout.updateLED(i / 3, r, g, b);
								}
							}
						}
					});
				}

				if (ESP8266Ws2812.layout == null) {
					System.out.println("[WS2812] write length:" + length);
				} else {
				}
			}
			return LuaValue.valueOf(true);
		}
	}

	public void setLayout(File file, LuaSimulation nodemcuSimu) {
		if (ESP8266Ws2812.layout == null) {
			ESP8266Ws2812.layout = WS2812Layout.parse(file, nodemcuSimu);
		}
	}
}
