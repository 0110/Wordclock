package de.c3ma.ollo;

/**
 * created at 29.12.2017 - 18:29:07<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * @author ollo<br />
 */
public interface LuaSimulation {

    public void rebootTriggered();

    public void setSimulationTime(long timeInMillis);

	public void setADC(int value);
}
