use glib_sys as glib;
use std::ffi::CStr;
use std::fmt;
use std::os::raw::c_char;

/// A Janus transaction ID. Used to correlate signalling requests and responses.
#[derive(Debug)]
pub struct TransactionId {
    ptr: *mut c_char,
}

impl TransactionId {
    /// Constructs a TransactionId from a pointer to a C string.
    /// The string must be allocated with glibc (e.g., via g_strdup).
    pub unsafe fn from_raw(ptr: *mut c_char) -> Self {
        Self { ptr }
    }
    pub fn as_ptr(&self) -> *mut c_char {
        self.ptr
    }
}

unsafe impl Send for TransactionId {}

impl fmt::Display for TransactionId {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        unsafe {
            if self.ptr.is_null() {
                f.write_str("<null>")
            } else {
                let contents = CStr::from_ptr(self.ptr);
                f.write_str(&contents.to_string_lossy())
            }
        }
    }
}

impl Drop for TransactionId {
    fn drop(&mut self) {
        unsafe { glib::g_free(self.ptr as *mut _) }
    }
}
