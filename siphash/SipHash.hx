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

	public function reset(k : haxe.io.Int32Array, mode128 : Bool = false)
	{
		v0 = Int64.make(k[1] ^ 0x736f6d65, k[0] ^ 0x70736575);
		v1 = Int64.make(k[3] ^ 0x646f7261, k[2] ^ 0x6e646f6d);
		v2 = Int64.make(k[1] ^ 0x6c796765, k[0] ^ 0x6e657261);
		v3 = Int64.make(k[3] ^ 0x74656462, k[2] ^ 0x79746573);
		
		this.mode128 = mode128;
		
		if (mode128) {
			v2 ^= 0x
		}
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

	function round() {
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

	static function getInt(a : haxe.io.Bytes, offset : Int) {
#if 0
		return a.get(offset + 3) << 24 |
			   a.get(offset + 2) << 16 |
			   a.get(offset + 1) << 8 |
			   a.get(offset);
#else
		return a.getInt32(offset);
#end
	}

	public function update(k : haxe.io.Bytes) {
		var i = 0;

		while (i <= k.length - 8) {
			var pi = Int64.make(getInt(k, i + 4), getInt(k, i + 0));
			i += 8;

			v3 ^= pi;

			var ci = v3.copy();

			round();
			round();

			v0 ^= pi;
		}
	}

	public function final() : Int64 {
		v2 ^= 0xff;

		round();
		round();
		round();
		round();

		v0 ^= v1;
		v2 ^= v3;
		v0 ^= v2;
		return v0;
	}
}
