package siphash;

import haxe.Int64;
import haxe.macro.Expr;

using StringTools;

class SipHash
{
	var v0 : Int64;
	var v1 : Int64;
	var v2 : Int64;
	var v3 : Int64;

	var mode128 : Bool = false;

	var stash : Int64 = 0;
	var stash_shift : Int = 0;

	var full_length = 0;

	public function reset(k : haxe.io.Int32Array, mode128 : Bool = false)
	{
		v0 = Int64.make(k[1] ^ 0x736f6d65, k[0] ^ 0x70736575);
		v1 = Int64.make(k[3] ^ 0x646f7261, k[2] ^ 0x6e646f6d);
		v2 = Int64.make(k[1] ^ 0x6c796765, k[0] ^ 0x6e657261);
		v3 = Int64.make(k[3] ^ 0x74656462, k[2] ^ 0x79746573);

		this.mode128 = mode128;

		if (mode128) {
			v1 ^= 0xee;
		}

		full_length = 0;
		stash = 0;
		stash_shift = 0;

		return this;
	}

	public function new() { }

	macro static function rotl(a : Expr, n : Int) : Expr {
#if 1
		return macro {
			var al = $e{a} << $v{n};
			var ah = $e{a} >>> (64 - $v{n});
			$e{a} = ah | al;
		}
#else
		return macro {
			var ah = ($e{a}.high << $v{n}) | ($e{a}.low >>> (32 - $v{n}));
			var al = ($e{a}.low << $v{n}) | ($e{a}.high >>> (32 - $v{n}));
			$e{a} = Int64.make(ah, al);
		}
#end
	}
	macro static function swap32(a : Expr) {
		return macro {
			var ah = $e{a}.low, al = $e{a}.high;
			$e{a} = Int64.make(ah, al);
		};
	}

	inline function round() {
		v0 += v1;
		v2 += v3;
		rotl(v1, 13);
		rotl(v3, 16);
		v1 ^= v0;
		v3 ^= v2;
		swap32(v0);
		v2 += v1;
		v0 += v3;
		rotl(v1, 17);
		rotl(v3, 21);
		v1 ^= v2;
		v3 ^= v0;
		swap32(v2);
	}

	static inline function getInt(a : haxe.io.Bytes, offset : Int) {
		return a.getInt32(offset);
	}

	public function update(k : haxe.io.Bytes, pos : Int = 0, ?len : Int) {
		var start = if (pos < 0) 0 else if (pos >= k.length) k.length - 1 else pos;

		var i = start;

		var end = if (len == null) k.length else pos + len;

		// reuse stash if updating from previous state
		if (stash_shift > 0) {
			while(stash_shift < 64 && i < end) {
				stash |= Int64.make(0,k.get(i)) << stash_shift;
				i++;
				stash_shift += 8;
			}

			if (stash_shift == 64) {
				v3 ^= stash;

				round();
				round();

				v0 ^= stash;
				stash_shift = 0;
			}
		}

		while (i <= end - 8) {
			var pi = Int64.make(getInt(k, i + 4), getInt(k, i + 0));
			i += 8;

			v3 ^= pi;

			round();
			round();

			v0 ^= pi;
		}

		// save for later
		if (i < end) {
			var s = 8;
			stash = k.get(i); i += 1;

			while (i < end) {
				stash |= Int64.make(0,k.get(i)) << s; s += 8; i += 1;
			}

			stash_shift = s;
		}

		full_length += end - start;

		return this;
	}

	private inline function end() {
		if (!mode128) {
			v2 ^= 0xff;
		} else {
			v2 ^= 0xee;
		}

		round();
		round();
		round();
		round();
	}

	public function complete() : Int64 {
		// need to append length
		stash |= Int64.make(0,full_length) << 56;

		// and run last rounds
		v3 ^= stash;

		round();
		round();

		v0 ^= stash;

		end();

		v0 ^= v1;
		v2 ^= v3;
		v0 ^= v2;
		return v0;
	}

	public function fast(buf : haxe.io.Bytes, pos : Int = 0, ? len : Int) : Int64 {

		if (len == null) len = buf.length - pos;

		var i = pos;

		while (i <= len - 8) {
			var pi = Int64.make(getInt(buf, i + 4), getInt(buf, i + 0));
			i += 8;

			v3 ^= pi;

			round();
			round();

			v0 ^= pi;
		}

		var last = Int64.make(len << 24, 0);
		var rem = len - i;

		if (rem >= 4) {
			last |= Int64.make(0, buf.getInt32(i));
			switch(rem) {
				case 7:
					last |= Int64.make(buf.getUInt16(i+4) | (buf.get(i+6) << 16), 0);
				case 6:
					last |= Int64.make(buf.getUInt16(i+4), 0);
				case 5:
					last |= Int64.make(buf.get(i), 0);
				default:
			}
		} else {
			switch(rem) {
				case 3:
					last |= Int64.make(0, buf.getUInt16(i) | (buf.get(i+2) << 16));
				case 2:
					last |= Int64.make(0, buf.getUInt16(i));
				case 1:
					last |= Int64.make(0, buf.get(i));
				default:
			}
		}

		v3 ^= last;

		round();
		round();

		v0 ^= last;

		end();

		v0 ^= v1;
		v2 ^= v3;
		v0 ^= v2;

		return v0;
	}

}
