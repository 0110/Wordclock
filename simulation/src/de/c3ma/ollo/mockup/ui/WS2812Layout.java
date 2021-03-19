package de.c3ma.ollo.mockup.ui;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Font;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSlider;
import javax.swing.JTextField;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;

import de.c3ma.ollo.LuaSimulation;

/**
 * created at 02.01.2018 - 12:57:02<br />
 * creator: ollo<br />
 * project: WS2812Emulation<br />
 * $Id: $<br />
 * 
 * @author ollo<br />
 */
public class WS2812Layout extends JFrame {

	/**
	 * 
	 */
	private static final long serialVersionUID = -6815557232118826140L;

	/**
	 * Parameter for the ADC brightness control
	 */
	private static final int ADC_INIT = 512;
	private static final int ADC_MIN = 0;
	private static final int ADC_MAX = 1024;

	private ArrayList<String> mLines = new ArrayList<String>();
	private int mColumn = 0;
	private int mRow = 0;
	private Element[][] mElements;

    private LuaSimulation nodemcuSimu;

	public WS2812Layout(LuaSimulation nodemcuSimu) {
	    this.nodemcuSimu = nodemcuSimu;
    }

    public static WS2812Layout parse(File file, LuaSimulation nodemcuSimu) {
		WS2812Layout layout = null;
		try {
			BufferedReader br = new BufferedReader(new FileReader(file));
			try {
				String line = br.readLine();
				if (line != null) {
					layout = new WS2812Layout(nodemcuSimu);
				}

				while (line != null) {
					if (!line.startsWith("#")) {
						layout.mLines.add(line);
						layout.mRow++;
						layout.mColumn = Math.max(layout.mColumn, line.length());
					}
					/* get the next line */
					line = br.readLine();
				}

				/* parse each line */
				layout.parse();
				layout.createAndDisplayGUI();
			} finally {
				if (br != null) {
					br.close();
				}
			}
		} catch (IOException ioe) {

		}
		return layout;
	}

	private void createAndDisplayGUI() {
		setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);

		JPanel contentPane = new JPanel();
		contentPane.setLayout(new BorderLayout());
		contentPane.setBorder(BorderFactory.createLineBorder(Color.DARK_GRAY, 2));

		JPanel ledPanel = new JPanel();
		ledPanel.setBackground(Color.BLACK);
		ledPanel.setLayout(new GridLayout(this.mRow, this.mColumn, 10, 10));
		for (int i = 0; i < this.mRow; i++) {
			for (int j = 0; j < this.mColumn; j++) {
				if (this.mElements[i][j] != null) {
					ledPanel.add(this.mElements[i][j]);
				}
			}
		}
		contentPane.add(ledPanel, BorderLayout.CENTER);
				
		JSlider adc = new JSlider(JSlider.VERTICAL,
                ADC_MIN, ADC_MAX, ADC_INIT);
		adc.addChangeListener(new ChangeListener() {
			
			@Override
			public void stateChanged(ChangeEvent e) {
				nodemcuSimu.setADC(adc.getValue());
			}
		});
		
		contentPane.add(adc, BorderLayout.EAST);
		
		JPanel bottomPanel = new JPanel();
				
		final JTextField dateTime = new JTextField("yyyy-mm-dd HH:MM:SS");
		dateTime.getDocument().addDocumentListener(new DocumentListener() {
		    public void changedUpdate(DocumentEvent e) {
		        warn();
		      }
		      public void removeUpdate(DocumentEvent e) {
		        warn();
		      }
		      public void insertUpdate(DocumentEvent e) {
		        warn();
		      }

		      public void warn() {
		         final String pattern = "(\\d{4})-(\\d{2})-(\\d{2}) (\\d{2}):(\\d{2}):(\\d{2})";
		         final String current = dateTime.getText();
		        
		         if (current.length() <=0) {
		             /* color "nothing" green */
		             dateTime.setForeground(Color.GREEN);
		             /* disable the time simulation */
		             nodemcuSimu.setSimulationTime(0);
		             return;
		         }
		         
		         if (!current.matches(pattern)) {
		             dateTime.setForeground(Color.RED);
		         } else {
		             dateTime.setForeground(Color.BLACK);
		             Pattern dateTimePattern = Pattern.compile(pattern);
		             Matcher matcher = dateTimePattern.matcher(current);
		             int year=0;
		             int month=0;
		             int day=0;
		             int hour=0;
		             int minute=0;
		             int second=0;
		             matcher.find();
		             for (int g = 1; g <= matcher.groupCount(); g++) {
		                 switch(g) {
		                 case 1: /* Year */
		                     year = Integer.parseInt(matcher.group(g));
		                     break;
		                 case 2: /* Month */
                             month = Integer.parseInt(matcher.group(g));
                             break;
		                 case 3: /* Day */
                             day = Integer.parseInt(matcher.group(g));
                             break;
		                 case 4: /* Hour */
                             hour = Integer.parseInt(matcher.group(g));
                             break;
		                 case 5: /* Minute */
                             minute = Integer.parseInt(matcher.group(g));
                             break;
		                 case 6: /* Second */
                             second = Integer.parseInt(matcher.group(g));
                             break;
		                 }	
		             }
		             System.out.println("[GUI] Set time to: " + year + "-" + month + "-" + day + " " + hour + ":" + minute + ":" + second);
		             GregorianCalendar gc = new GregorianCalendar(year, month, day, hour, minute, second);
		             
		             nodemcuSimu.setSimulationTime(gc.getTimeInMillis());
		         }
		      }
		    });
		bottomPanel.add(dateTime);

        final JButton btnSetCurrentTime = new JButton("Set time");
        btnSetCurrentTime.setActionCommand("Set time");
        btnSetCurrentTime.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent ae) {
                JButton but = (JButton) ae.getSource();
                if (but.equals(btnSetCurrentTime)) {
                    GregorianCalendar gc = new GregorianCalendar();
                    dateTime.setText(String.format("%d-%02d-%02d %02d:%02d:%02d",
                            gc.get(Calendar.YEAR), gc.get(Calendar.MONTH), gc.get(Calendar.DAY_OF_MONTH),
                            gc.get(Calendar.HOUR_OF_DAY), gc.get(Calendar.MINUTE), gc.get(Calendar.SECOND)));
                }
            }
        });
        bottomPanel.add(btnSetCurrentTime);
        
		final JButton btnReboot = new JButton("Reboot");
		btnReboot.setActionCommand("Reboot simulation");
		btnReboot.addActionListener(new ActionListener() {
			public void actionPerformed(ActionEvent ae) {
				JButton but = (JButton) ae.getSource();
				if (but.equals(btnReboot)) {
				    System.out.println("[Node] Restart");
		            nodemcuSimu.rebootTriggered();
				}
			}
		});
		bottomPanel.add(btnReboot);
		
		contentPane.add(bottomPanel, BorderLayout.SOUTH);

		setContentPane(contentPane);
		pack();
		setLocationByPlatform(true);
		setVisible(true);
	}

	private void parse() {
		this.mElements = new Element[this.mRow][this.mColumn];
		int row = 0;
		for (String line : this.mLines) {
			for (int i = 0; i < line.length(); i++) {
				char c = line.charAt(i);
				if ((('A' <= c) && (c <= 'Z')) || (('0' <= c) && (c <= '9')) || (c == 'Ä') || (c == 'Ö')
						|| (c == 'Ü')) {
					this.mElements[row][i] = new Element(c);
				} else {
					this.mElements[row][i] = new Element();
				}
				this.mElements[row][i].setColor(0, 0, 0);
			}
			row++;
		}
	}

	public class Element extends JLabel {

		/**
		 * 
		 */
		private static final long serialVersionUID = -3933903441113933637L;

		private boolean noText = false;

		/**
		 * Draw a simple rect
		 */
		public Element() {
			super();
			this.noText = true;
			this.setBackground(Color.BLACK);
		}

		/**
		 * Draw a character
		 * 
		 * @param character
		 *            to show
		 */
		public Element(char character) {
			super("" + character);
			setFont(new Font("Dialog", Font.BOLD, 24));
			setHorizontalAlignment(CENTER);
			// FIXME: Background color is not updated:
			this.setBackground(Color.BLACK);
		}

		public void setColor(int red, int green, int blue) {
			this.setForeground(new Color(red, green, blue));
			this.repaint();
		}
		
		public Color getColor() {
			return this.getForeground();
		}

		@Override
		public String toString() {
			StringBuilder sb = new StringBuilder();
			if (noText) {
				sb.append(" ");
			} else {
				sb.append("" + this.getText());
			}
			sb.append("|" + Integer.toHexString(this.getForeground().getRed()) + " "
					+ Integer.toHexString(this.getForeground().getGreen()) + " "
					+ Integer.toHexString(this.getForeground().getBlue()));

			return sb.toString();
		}
	}

	public void updateLED(int index, int r, int g, int b) {
		if (mElements != null) {
			int i = (index / mColumn);
			int j = (index % mColumn);
			// Swap each second row
			if (i % 2 == 1) {
				j = (mColumn-1) - j;
			}
			if ((i < mElements.length) && (j < mElements[i].length) && (mElements[i][j] != null)) {
				Element curlbl = mElements[i][j];
				curlbl.setColor(r, g, b);
			}
		}
	}
	
	public Element getLED(int index) {
		if (mElements != null) {
			int i = (index / mColumn);
			int j = (index % mColumn);
			if (i % 2 == 1) {
				j = (mColumn-1) - j;
			}
			if ((i < mElements.length) && (j < mElements[i].length) && (mElements[i][j] != null)) {
				return mElements[i][j];
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
	
	public void fillLEDs(int r, int g, int b) {
		if (mElements != null) {
			for(int i=0;(i < mElements.length); i++) {
				for (int j=0; (j < mElements[i].length); j++) {
					if  (mElements[i][j] != null) {
						Element curlbl = mElements[i][j];
						curlbl.setColor(r, g, b);
					}
				}
			}
		}
	}

}
