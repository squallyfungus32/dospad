#ifndef DOSBOX_MIDI_FLUIDSYNTH_H
#define DOSBOX_MIDI_FLUIDSYNTH_H

/*
 *  Copyright (C) 2002-2011  The DOSBox Team
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <fluidsynth.h>
#include <string.h>

#include "mixer.h"

#ifdef C_WORDEXP
#include <wordexp.h>
#endif

class MidiHandler_fluidsynth : public MidiHandler {
private:	
	std::string soundfont;
	int soundfont_id;
	fluid_settings_t *settings;
	fluid_synth_t *synth;
    
    MixerChannel *synth_chan;
    
    static void mixerCallBack(Bitu len);
    
    void handleMixerCallBack(Bitu len);
    
    MidiHandler_fluidsynth();
    ~MidiHandler_fluidsynth();
    
public:
	static MidiHandler_fluidsynth &GetInstance(void);
    
    const char* GetName(void);
    void PlaySysex(Bit8u * sysex,Bitu len);
    void PlayMsg(Bit8u * msg);
    void Close(void);
    bool Open(const char * conf);
};

#endif /* DOSBOX_MIDI_FLUIDSYNTH_H */
