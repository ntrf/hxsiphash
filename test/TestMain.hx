package ;

import siphash.SipHash;

import haxe.Int64;

class SipHashReferenceTest extends haxe.unit.TestCase {

	var key : haxe.io.Int32Array = new haxe.io.Int32Array(4);

	public function new() {
		super();

		key[0] = 0x03020100;
		key[1] = 0x07060504;
		key[2] = 0x0b0a0908;
		key[3] = 0x0f0e0d0c;
	}

	public function testInitialState() {
		var state = new SipHash();

		state.reset(key);

		assertEquals((@:privateAccess state.v0).high, 0x74696861); assertEquals((@:privateAccess state.v0).low, 0x73716475);
		assertEquals((@:privateAccess state.v1).high, 0x6b617f6d); assertEquals((@:privateAccess state.v1).low, 0x656e6665);
		assertEquals((@:privateAccess state.v2).high, 0x6b7f6261); assertEquals((@:privateAccess state.v2).low, 0x6d677361);
		assertEquals((@:privateAccess state.v3).high, 0x7b6b696e); assertEquals((@:privateAccess state.v3).low, 0x727e6c7b);
	}

	public function testPostUpdate1State() {
		var state = new SipHash();

		state.reset(key);

		var data = haxe.io.Bytes.alloc(8);
		for (i in 0 ... 8) data.set(i, i);

		state.update(data);

		assertEquals((@:privateAccess state.v0).high, 0x4a017198); assertEquals((@:privateAccess state.v0).low, 0xde0a59e0);
		assertEquals((@:privateAccess state.v1).high, 0x0d52f6f6); assertEquals((@:privateAccess state.v1).low, 0x2a4f59a4);
		assertEquals((@:privateAccess state.v2).high, 0x634cb357); assertEquals((@:privateAccess state.v2).low, 0x7b01fd3d);
		assertEquals((@:privateAccess state.v3).high, 0xa5224d6f); assertEquals((@:privateAccess state.v3).low, 0x55c7d9c8);
	}

	public function testPostUpdate2State() {
		var state = new SipHash();

		state.reset(key);

		var data = haxe.io.Bytes.alloc(16);
		for (i in 0 ... 16) data.set(i, i);

		state.update(data);

		assertEquals((@:privateAccess state.v0).high, 0x3c85b3ab); assertEquals((@:privateAccess state.v0).low, 0x6f55be51);
		assertEquals((@:privateAccess state.v1).high, 0x414fc3fb); assertEquals((@:privateAccess state.v1).low, 0x98efe374);
		assertEquals((@:privateAccess state.v2).high, 0xccf13ea5); assertEquals((@:privateAccess state.v2).low, 0x27b9f442 ^ 0xff);
		assertEquals((@:privateAccess state.v3).high, 0x5293f5da); assertEquals((@:privateAccess state.v3).low, 0x84008f82);
	}

	public function testEndResult() {
		var state = new SipHash();

		state.reset(key);

		var data = haxe.io.Bytes.alloc(15);
		for (i in 0 ... 15) data.set(i, i);

		state.update(data);

		assertEquals((@:privateAccess state.stash_shift), 56);

		var res = state.complete();

		assertEquals(res.high, 0xa129ca61);
		assertEquals(res.low,  0x49be45e5);
	}
}

class SipHashStreamTest extends haxe.unit.TestCase {
	var key : haxe.io.Int32Array = new haxe.io.Int32Array(4);

	public function new() {
		super();

		key[0] = 0x03020100;
		key[1] = 0x07060504;
		key[2] = 0x0b0a0908;
		key[3] = 0x0f0e0d0c;
	}

	public function testSplit3bytes() {
		var state = new SipHash();

		state.reset(key);

		var data1 = haxe.io.Bytes.alloc(3);
		for (i in 0 ... 3) data1.set(i, i);

		var data2 = haxe.io.Bytes.alloc(9);
		for (i in 0 ... 9) data2.set(i, i + 3);

		var data3 = haxe.io.Bytes.alloc(3);
		for (i in 0 ... 3) data3.set(i, i + 12);

		state.update(data1);

		assertEquals(24, (@:privateAccess state.stash_shift));
		assertEquals(0x020100, (@:privateAccess state.stash.low));
		assertEquals(0, (@:privateAccess state.stash.high));

		state.update(data2);

		assertEquals(32, (@:privateAccess state.stash_shift));
		assertEquals(0x0b0a0908, (@:privateAccess state.stash.low));
		assertEquals(0x00000000, (@:privateAccess state.stash.high));

		state.update(data3);

		assertEquals(0x0b0a0908, (@:privateAccess state.stash.low));
		assertEquals(0x000e0d0c, (@:privateAccess state.stash.high));
		assertEquals(56, (@:privateAccess state.stash_shift));

		var res = state.complete();

		assertEquals(res.high, 0xa129ca61);
		assertEquals(res.low,  0x49be45e5);
	}

	public function testBufferSliceBytes() {
		var state = new SipHash();

		state.reset(key);

		var data = haxe.io.Bytes.alloc(15);
		for (i in 0 ... 15) data.set(i, i);

		state.update(data, 0, 3);
		state.update(data, 3, 9);
		state.update(data, 12,3);

		var res = state.complete();

		assertEquals(res.high, 0xa129ca61);
		assertEquals(res.low,  0x49be45e5);
	}
}

class SipHashFastTest extends haxe.unit.TestCase {
	var key : haxe.io.Int32Array = new haxe.io.Int32Array(4);

	public function new() {
		super();

		key[0] = 0x03020100;
		key[1] = 0x07060504;
		key[2] = 0x0b0a0908;
		key[3] = 0x0f0e0d0c;
	}

	public function testFastInterface() {
		var state = new SipHash();

		state.reset(key);

		var data = haxe.io.Bytes.alloc(15);
		for (i in 0 ... 15) data.set(i, i);

		var res = state.fast(data);

		assertEquals(res.high, 0xa129ca61);
		assertEquals(res.low,  0x49be45e5);
	}
}

class TestMain {
	static function main() {
		var r = new haxe.unit.TestRunner();
		r.add(new SipHashReferenceTest());
		r.add(new SipHashStreamTest());
		r.add(new SipHashFastTest());
		r.run();
	}
}
