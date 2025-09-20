s.waitForBoot({

      // tempo
      TempoClock.default.tempo = 120/60; // 120 bpm i think
      ~clk = TempoClock.default;

      // ---- KICK
      SynthDef(\kik, { |out=0, amp=0.9, f=50|
            var e, body, click;
            e = EnvGen.ar(Env.perc(0.001, 0.25, 1, -4), doneAction:2);
            body = SinOsc.ar(f * (1 + (EnvGen.ar(Env([2,1],[0.04],-4))))) * e;
            click = HPF.ar(WhiteNoise.ar(0.2), 5000) * e * 0.3;
            Out.ar(out, (body + click)!2 * amp);
      }).add;

      // ---- HAT
      SynthDef(\hat, { |out=0, amp=0.2|
            var e, n;
            e = EnvGen.ar(Env.perc(0.001, 0.08), doneAction:2);
            n = BPF.ar(WhiteNoise.ar, 9000, 0.4) * e;
            Out.ar(out, n!2 * amp);
      }).add;

      // ---- BASs
      SynthDef(\bas, { |out=0, amp=0.7, rel=0.2, freq=55|
            var e, s;
            e = EnvGen.ar(Env.perc(0.002, rel, 1, -6), doneAction:2);
            s = Saw.ar(freq) * e;
            s = LPF.ar(HPF.ar(s, 35), 1200);
            s = tanh(s * 2); // lil crunch
            Out.ar(out, s!2 * amp);
      }).add;

      // ---- KEYS
      SynthDef(\keys, { |out=0, amp=1.6, freq=440, delMix=0.3, delTime=0.375, delDecay=1.8|
            var e, mod, dry, wet, mix;
            e = EnvGen.ar(Env.perc(0.01, 1.2, 0.6), doneAction:2);
            mod = SinOsc.ar(freq * 2, 0, freq * 0.4);
            dry = (SinOsc.ar(freq + mod) + (Pulse.ar(freq*0.5,0.4)*0.2)) * e;
            dry = HPF.ar(dry, 200);
            dry = LPF.ar(dry, 5000);
            wet = CombC.ar(dry, 1.0, delTime, delDecay); // not perfectly synced but close enough
            mix = XFade2.ar(dry, wet, (delMix*2-1));
            mix = Limiter.ar(mix, 0.95);
            Out.ar(out, mix!2 * amp);
      }).add;

      s.sync;

      ~ch = [
            [57,60,64,67],[57,60,64,67],
            [53,57,60,64],[53,57,60,64],
            [55,59,62,67],[55,59,62,67],
            [52,55,59,62],[52,55,59,62]
      ];

      // helper
      ~m2f = { |m| if(m.isKindOf(Rest), { Rest() }, { m.midicps }) };

      //  patterns

      // kick: 4
      Pdef(\kick, Pbind(
            \instrument, \kik,
            \dur, 1,
            \amp, 0.8
      )).play;

      // hats: 16a
      Pdef(\hat, Pbind(
            \instrument, \hat,
            \dur, 0.25,
            \amp, Pseq([0.22,0.1,0.16,0.11].scramble, inf)
      )).play;


      ~melNotes = ~ch.collect { |c|
            [
                  c[0], c[1], c[2], c[3], c[2], c[1], c[0], Rest(),
                  c[1], c[3]+12, c[2], c[1], c[0]-12, Rest()
            ]
      }.flatten;

      ~melDurs = [0.25,0.25,0.25,0.25,  0.5,0.25,0.25,0.25,  0.5,0.25,0.25,0.25,  0.5,0.25];

      Pdef(\mel, Pbind(
            \instrument, \keys,
            \freq, Pseq(~melNotes.collect(~m2f), inf),
            \dur,  Pseq(~melDurs, inf),
            \amp,  1.0,
            \legato, 0.9,
            \delTime, Pfunc { (60 / ~clk.tempo) * 0.75 }, // dotted 8th-ish
            \delMix, 0.35,
            \delDecay, 2.0
      ));

      // bass
      ~bassRoots = [45,45,41,41,43,43,40,40]; // A2 A2 F2 F2 G2 G2 E2 E2
      ~bassSeq = Array.new;
      ~bassDur = Array.new;

      ~bassRoots.do { |r|
            var up, tmp;
            up = r + 12;
            tmp = [
                  Rest(),0.5,  up,0.5,
                  r,0.25, up,0.25,
                  Rest(),0.5,
                  up,0.25, r,0.25, up,0.5
            ];
            tmp.clump(2).do { |p|
                  ~bassSeq = ~bassSeq.add(p[0]);
                  ~bassDur = ~bassDur.add(p[1]);
            };
      };

      Pdef(\bas, Pbind(
            \instrument, \bas,
            \freq, Pseq(~bassSeq.collect(~m2f), inf),
            \dur,  Pseq(~bassDur, inf),
            \rel,  0.22,
            \amp,  0.85
      ));

      //  timing

      ~clk.sched(8,  { Pdef(\mel).play; nil });   // 2 bars
      ~clk.sched(24, { Pdef(\bas).play; nil });   // +4 bars

      l
});