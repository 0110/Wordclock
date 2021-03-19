package de.c3ma.ollo.mockup;

import java.awt.Color;
import java.io.File;

import javax.swing.SwingUtilities;

import org.luaj.vm2.LuaNil;
import org.luaj.vm2.LuaString;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.VarArgFunction;
import org.luaj.vm2.lib.ZeroArgFunction;

import de.c3ma.ollo.LuaSimulation;
import de.c3ma.ollo.LuaThreadTmr;
import de.c3ma.ollo.mockup.ui.WS2812Layout;
import de.c3ma.ollo.mockup.ui.WS2812Layout.Element;

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
		ws2812.set("newBuffer", new newBuffer());
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

				if (ESP8266Ws2812.layout == null) {
					System.err.println("[WS2812] Not initialized (" + length + "bytes to be updated)");
					return LuaValue.valueOf(false);
				}
				
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
				return LuaValue.valueOf(true);
			} else {
				System.out.println("[WS2812] write no string given");
				return LuaValue.NIL;
			}
		}
	}

	public void setLayout(File file, LuaSimulation nodemcuSimu) {
		if (ESP8266Ws2812.layout == null) {
			ESP8266Ws2812.layout = WS2812Layout.parse(file, nodemcuSimu);
		}
	}
	
	private class newBuffer extends VarArgFunction {
    	
        public Varargs invoke(Varargs varargs) {
            if (varargs.narg() == 2) {
                final int leds = varargs.arg(1).toint();
                final int bytesPerLeds = varargs.arg(2).toint();
                final LuaTable rgbBuffer = new LuaTable();
                rgbBuffer.set("fill", new bufferFill());
                rgbBuffer.set("set", new bufferWrite());
                rgbBuffer.set("get", new bufferRead());
                System.out.println("[WS2812] " + leds + "leds (" + bytesPerLeds + "bytes per led)");                
                return rgbBuffer;
            } else {
            	return LuaValue.NIL;
            }
        }
    }
	
	private class bufferFill extends VarArgFunction {
    	
        public Varargs invoke(Varargs varargs) {
            if (varargs.narg() >= 3) {
                final int red = varargs.arg(1).toint();
                final int green = varargs.arg(2).toint();
                final int blue = varargs.arg(3).toint();
                if (ESP8266Ws2812.layout != null) {
                	SwingUtilities.invokeLater(new Runnable() {
						@Override
						public void run() {
							ESP8266Ws2812.layout.fillLEDs(red, green, blue);
						}
                	});
				}
                System.out.println("[WS2812] buffer fill with " + red + "," + green + "," +  blue);
                return LuaValue.valueOf(true);
            } else if (varargs.isstring(2)) {
            	 final LuaString color = varargs.arg(2).checkstring();
 				final int length = color.rawlen();
 				if ((length == 3) && (ESP8266Ws2812.layout != null)) {

 					final byte[] array = color.m_bytes;
 					final int r = array[0]+(Byte.MIN_VALUE*-1);
 					final int b = array[1]+(Byte.MIN_VALUE*-1);
 					final int g = array[2]+(Byte.MIN_VALUE*-1);
 					SwingUtilities.invokeLater(new Runnable() {
						@Override
						public void run() {
		 					ESP8266Ws2812.layout.fillLEDs(r, g, b);
						} 
					});
 	 				System.out.println("[WS2812] buffer fill with " + r + "," + g + "," +  b);
 	 				return LuaValue.valueOf(true);
 				} else {
 					System.err.println("[WS2812] buffer not initialized ("+varargs.narg() +"args) , length "+ length + ", raw:" + color.toString());
 	 				return LuaValue.NIL;
 				}
            } else {
            	System.err.println("[WS2812] fill with " + varargs.narg() + " arguments undefined.");
            	return LuaValue.NIL;
            }
        }
    }
	
	private class bufferWrite extends VarArgFunction {
    	
        public Varargs invoke(Varargs varargs) {
            if (varargs.narg() == 3) {
                final int index = varargs.arg(2).toint();
                
                
                final LuaString color = varargs.arg(3).checkstring();
 				final int length = color.rawlen();
				if (length == 3) {
					SwingUtilities.invokeLater(new Runnable() {
						@Override
						public void run() {
							final byte[] array = color.m_bytes;
							int r = array[0]+(Byte.MIN_VALUE*-1);
							int b = array[1]+(Byte.MIN_VALUE*-1);
							int g = array[2]+(Byte.MIN_VALUE*-1);
							ESP8266Ws2812.layout.updateLED(index, r, g, b);
						}
					});
	                return LuaValue.valueOf(true);
				} else {
					for(int i=0; i <= varargs.narg(); i++) {
						System.err.println("[WS2812] write ["+(i) + "] (" + varargs.arg(i).typename() + ") " + varargs.arg(i).toString() );
					}
					
					System.err.println("[WS2812] set with " + varargs.narg() + " arguments at index="+ index + " and "+ length + " charactes not matching");
	            	return LuaValue.NIL;	
				}
            } else {
            	System.err.println("[WS2812] set with " + varargs.narg() + " arguments undefined.");
            	return LuaValue.NIL;
            }
        }
    }
	
	private class bufferRead extends OneArgFunction {

		@Override
		public LuaValue call(LuaValue arg) {			
			final int offset = arg.toint();
			if (ESP8266Ws2812.layout != null) {
				
				Element e = ESP8266Ws2812.layout.getLED(offset);
				if (e != null) {
					Color color = e.getColor();
					final byte[] array = new byte[3];
					array[0] = (byte) color.getRed();
					array[1] = (byte) color.getGreen();
					array[2] = (byte) color.getBlue();
					return LuaString.valueOf(array);
				}
			}

			System.err.println("[WS2812] reading " + offset + " impossible");
			return LuaValue.NIL;
		}
	}
}
