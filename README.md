NOZOKI -- ORIGINAL ATLUS WEBPAGE & ASSETS BUNDLE
================================================
https://spswierc.github.io/Persona4_FlashGame/assets/play.html

START
-----
Double-click Start-Nozoki.cmd (Windows, PowerShell 5.1+).Keep its window open while playing; closing stops the local server.

FORM FIELDS
-----------
The original form.swf has an internal mismatch. Its TextInput instance is
named "url", and the copy button reads url.text, but its initialization
writes to _root.code.text. The supplied form_url.swf and form_banner.swf
retain original Flash controls while changing the initializer to write to
_root.url.text and embedding the corresponding initial string.

This targets a specific code mismatch, but actual rendering/copying in Ruffle
has not been verified.
