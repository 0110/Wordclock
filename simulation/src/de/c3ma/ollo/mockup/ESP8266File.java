package de.c3ma.ollo.mockup;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;

import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.OneArgFunction;
import org.luaj.vm2.lib.TwoArgFunction;

/**
 * created at 29.12.2017 - 01:08:53<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public class ESP8266File extends TwoArgFunction {

    private File workingDir = null;
    
    private File openedFile = null;
    
    private String SHRINKED_FILE_POSTFIX = "_diet";
    
    @Override
    public LuaValue call(LuaValue modname, LuaValue env) {
        env.checkglobals();
        final LuaTable file = new LuaTable();
        file.set("open", new OpenFunction());
        file.set("list", new ListFunction());
        file.set("remove", new RemoveFunction());
        env.set("file", file);
        env.get("package").get("loaded").set("file", file);
                
        return file;
    }
 
    private class ListFunction extends TwoArgFunction {

        @Override
        public LuaValue call(LuaValue arg1, LuaValue arg2) {
            final LuaTable fileList = new LuaTable();
            
            if ((workingDir != null) && (workingDir.exists())) {
                File[] files = workingDir.listFiles();
                for (File file : files) {
                    fileList.set(file.getName(), file.getAbsolutePath());
                }
            }
            
            return fileList;
        }
        
    }
    
    private class OpenFunction extends OneArgFunction {

        @Override
        public LuaValue call(LuaValue fileName) {
            
            final String codeFileName = fileName.checkjstring();
            final File f = new File( workingDir.getAbsolutePath() + File.separator + codeFileName);
            // Check if the file exists as it
            if (f.exists()) {
                ESP8266File.this.openedFile = f;
            } else {
            	if (codeFileName.contains(SHRINKED_FILE_POSTFIX)) {
                	File fShrinked = new File( workingDir.getAbsolutePath() + File.separator + codeFileName.replace(SHRINKED_FILE_POSTFIX, ""));
                	File fShrinkedLC = new File(fShrinked.getAbsolutePath().replace(".lua", ".lc"));
                	if (!fShrinkedLC.exists()) {
	                	try {
	                		System.out.println("[FILE] Generate " + codeFileName);
	                    	Files.copy(fShrinked.toPath(), f.toPath());
						} catch (IOException e) {
							System.err.println("[FILE] Generate " + codeFileName + " failed: " + e.getMessage());
						}
                	} else {
                		System.out.println("[FILE] Already found " + fShrinkedLC.getName());
                		return LuaValue.valueOf(true);
                	}
            	}
            }
            
            return LuaValue.valueOf((f.exists()));
        }
        
    }

    private class RemoveFunction extends OneArgFunction {

        @Override
        public LuaValue call(LuaValue fileName) {
            
            final String luaFileName = fileName.checkjstring();
            System.out.println("[FILE] Removing " + luaFileName);
            File f = new File(workingDir.getAbsolutePath() + File.separator + fileName);
            if (f.exists()) {
                return LuaValue.valueOf(f.delete());
            } else {
                return LuaValue.valueOf(false);   
            }
        }
        
    }
    
    public void setWorkingDirectory(File workingDir) {
        this.workingDir = workingDir;        
    }

    public File getFileInWorkingDir(String filename) {
        File f = new File (workingDir.getAbsolutePath() + File.separator + filename);
        if (f.exists()) {
            return f;
        } else {
            return null;
        }
    }
}
