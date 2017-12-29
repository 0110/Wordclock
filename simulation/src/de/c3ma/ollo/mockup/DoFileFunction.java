package de.c3ma.ollo.mockup;

import java.io.File;

import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.OneArgFunction;

/**
 * created at 29.12.2017 - 20:23:48<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class DoFileFunction extends OneArgFunction {

    private File workingDir = null;
    private Globals globals;
    
    public DoFileFunction(Globals globals) {
        this.globals = globals;
    }

    @Override
    public LuaValue call(LuaValue luaFilename) {
        String filename = luaFilename.checkjstring();
        
        System.out.println("[Nodemcu] dofile " + filename);
        
        File f = new File(workingDir.getAbsolutePath() + File.separator + filename);
        
        if (f.exists()) {
            LuaValue chunk = this.globals.loadfile(f.getAbsolutePath());
            chunk.call();
            return LuaValue.valueOf(true);
        } else {
            return LuaValue.valueOf(false);
        }
    }

    public void setWorkingDirectory(File workingDir) {
        this.workingDir = workingDir;
    }

}
