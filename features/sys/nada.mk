# This makes the root password empty. If a container image is being built to be
# converted into a bootable image, it may be that entry into the resulting
# (physical or virtual) system requires an interactive login as root. In such
# cases, having a null password is preferable to an unknown password, because
# it allows an initial login so that the root user can set a password they
# know. I'll keep the security preaching to a minimum, but just to be clear:
# nulling the root password really only makes sense if you'll need interactive
# login and need to be able to log in "insecurely" in order to initialize the
# root password to something knowable.  Making the password (temporarily) null
# is simply that "insecure" stepping stone.
#
# BTW: standard alternatives of setting a root password to "root" or "default"
# or "admin" (or whatever) are worse - an attack on such a system will succeed
# almost as easily as if there was no password at all, but the superficial
# appearance that the root account is password-protected could very well lull
# the system owner into not rectifying such a trivially-weak password choice. A
# null/empty password does not pretend to be more secure than it is, which in a
# sense makes it slightly more secure - because it's more obvious that the
# password needs to be changed if password-protection is expected.
#
# See the note in "debian/apt_is_usable.mk"

$(eval F := nada)
$(eval $F_PREFIX := sys)
$(eval $F_FN := feature_$(subst /,__,$($F_PREFIX)/$F))

$(eval $($F_FN)_loaded := 1)
define $($F_FN)
	$(eval F := nada)
	$(eval $(call trace,start $($F_FN)($1,$2,$3)))
	$(eval FPARAM_NEW_IMAGE := $(strip $1))
	$(eval FPARAM_BASE_IMAGE := $(strip $2))
	$(eval FPARAM_FEATURE_PATH := $(strip $3))

	$(eval $(call trace,setting attributes for IMAGE $(FPARAM_NEW_IMAGE)))
	$(eval $(FPARAM_NEW_IMAGE)_DESCRIPTION := Mariner feature layer '$F')
	$(eval $(FPARAM_NEW_IMAGE)_NOPATH := true)
	$(eval $(FPARAM_NEW_IMAGE)_DOCKERFILE := /dev/null)

	$(eval $(call trace,end $($F_FN)($1,$2,$3)))
endef
