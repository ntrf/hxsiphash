
======================
Siphash-2-4 for Haxe
======================

See the `SipHash home page <https://131002.net/siphash/>`_ for info.

Usage
======

Stream interface
-----------------

You need to create a state object of class ``siphash.SipHash``::

    var sh = new siphash.SipHash();

Then you need to specify a key. This operation also resets the internal state, so you can use it
to start a new authentication without creating new state::

    sh.reset(key);

Next you feed it buffers of data you want authenticated. Note, that each next block of data adds
to stream, not replaces it. If you feed it blocks that aren't multiples of 8 bytes, remainder of
data will be stored inside and used with the begining of next block::

    sh.update(buffer, 10 /* offset */, len - 10 /* length */);
    sh.update(buffer, 10); // same as above
    sh.update(buffer); // use th whole buffer

Finally you make the authentication tag::

    var tag : haxe.Int64 = sh.complete();

Fast interface
-----------------

Or if you just need to hash one buffer::

    var sh = new siphash.SipHash(); // do this once

    var result = sh.reset(key).fast(buffer, 10, 25); // do this for every buffer

This interface is slightly faster as it doesn't save intermediate state while reading the buffer.

Class reference
================

class ``siphash.SipHash``
~~~~~~~~~~~~~~~~~~~~~~~~~

``public function reset(k : haxe.io.Int32Array, mode128 : Bool = false)``
    Resets internal state and initializes it with provided key. Allows more than one plaintext to
    be processed with a single ``SipHash`` object.

``public function update(k : haxe.io.Bytes, pos : Int = 0, ?len : Int)``
    Updates internal state with provided buffer. If ``len`` is unspecified, uses ``k.length - pos``
    bytes from buffer.

``public function complete() : Int64``
    Completes the final transform and outputs authentication tag.

``public function fast(buf : haxe.io.Bytes, pos : Int = 0, ? len : Int) : Int64``
    Does ``update`` and ``complete`` in one call. Faster, but supports only one buffer.
