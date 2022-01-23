package de.c3ma.ollo.mockup;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;
import org.luaj.vm2.lib.ZeroArgFunction;

import de.c3ma.ollo.LuaSimulation;

/**
 * created at 29.12.2017 - 01:29:40<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class ESP8266Node extends TwoArgFunction {

    private File workingDir = null;
    private LuaSimulation nodemcuSimu;
    
    public ESP8266Node(LuaSimulation nodemcuSimu) {
        this.nodemcuSimu = nodemcuSimu;
    }

    @Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable node = new LuaTable();
        node.set("compile", new CompileFunction());
        node.set("restart", new RestartFunction());
        node.set("heap", new HeapFunction());
        env.set("node", node);
        env.get("package").get("loaded").set("node", node);        
        return node;
    }

    private class CompileFunction extends OneArgFunction {

        @Override
        public LuaValue call(LuaValue fileName) {
            final String codeFileName = fileName.checkjstring();
            final String compiledFileName = fileName.checkjstring().replace(".lua", ".lc");
            final File f = new File( workingDir.getAbsolutePath() + File.separator + codeFileName);
            System.out.println("[Node] Compiling " + compiledFileName);
            final File outf = new File( workingDir.getAbsolutePath() + File.separator + compiledFileName);
            if (f.exists()) {
                //Simply copy the file as .lc file
                try {
                    Files.copy(f.toPath(), outf.toPath());
                } catch (IOException e) {
                    return LuaValue.valueOf(false);
                }
            }
            
            return LuaValue.valueOf(f.exists());
        }
        
    }
    
    private class RestartFunction extends ZeroArgFunction {

        @Override
        public LuaValue call() {
            System.out.println("[Node] Restart");
            nodemcuSimu.rebootTriggered();
            return LuaValue.valueOf(false);
        }
        
    }
    
    private class HeapFunction extends ZeroArgFunction {

        @Override
        public LuaValue call() {
            //System.out.println("[Node] Heap");      
            return LuaValue.valueOf(Runtime.getRuntime().freeMemory());
        }
        
    }
    

    
    public void setWorkingDirectory(File workingDir) {
        this.workingDir = workingDir;        
    }
}
