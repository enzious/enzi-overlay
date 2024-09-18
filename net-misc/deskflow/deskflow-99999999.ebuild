# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit cmake desktop xdg-utils virtualx

MY_P=deskflow-99999999
GTEST_COMMIT=18f8200e3079b0e54fa00cb7ac55d4c39dcf6da6
MY_COMMIT=""

inherit git-r3
EGIT_REPO_URI="https://github.com/enzious/deskflow.git"
EGIT_BRANCH="test"

DESCRIPTION="Lets you easily share a single mouse and keyboard between multiple computers"
HOMEPAGE="https://symless.com/synergy https://github.com/symless/synergy-core/"
SRC_URI="
	https://dev.gentoo.org/~mgorny/dist/synergy-1.12.0.png
	test? (
		https://github.com/google/googletest/archive/${GTEST_COMMIT}.tar.gz
			-> googletest-${GTEST_COMMIT}.tar.gz
	)
"
S=${WORKDIR}/${MY_P}

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="gui test"
RESTRICT="!test? ( test )"

RDEPEND="
	dev-libs/glib
	dev-libs/openssl:=
	dev-qt/qtdbus:5
	x11-libs/gdk-pixbuf
	x11-libs/libICE:=
	x11-libs/libSM:=
	x11-libs/libX11:=
	x11-libs/libXext:=
	x11-libs/libXi:=
	x11-libs/libXinerama:=
	x11-libs/libXrandr:=
	x11-libs/libXtst:=
	x11-libs/libnotify
	gui? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtnetwork:5
		dev-qt/qtwidgets:5
	)
"
DEPEND="
	${RDEPEND}
	x11-base/xorg-proto
"
BDEPEND="
	gui? (
		dev-qt/linguist-tools:5
	)"

DOCS=( ChangeLog doc/deskflow.conf.example{,-advanced,-basic} )

#PATCHES=(
#	"${FILESDIR}"/${PN}-1.14.1.32-gcc13.patch
#)

src_unpack() {
	git-r3_src_unpack
}

src_prepare() {
	# broken on Xvfb
	rm src/test/integtests/platform/XWindowsScreenTests.cpp || die

	if use test; then
		rmdir ext/googletest || die
		mv "${WORKDIR}/googletest-${GTEST_COMMIT}" ext/googletest || die
	fi

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DDESKFLOW_BUILD_LEGACY_GUI=$(usex gui)
		-DDESKFLOW_BUILD_LEGACY_INSTALLER=OFF
		-DBUILD_TESTS=$(usex test)
	)

	cmake_src_configure
}

my_test() {
	"${BUILD_DIR}"/bin/unittests &&
	"${BUILD_DIR}"/bin/integtests
}

src_test() {
	virtx my_test
}

src_install() {
	dobin "${BUILD_DIR}"/bin/deskflow{c,s,-legacy}

	if use gui; then
		newbin "${BUILD_DIR}"/bin/deskflow qdeskflow
		newicon -s 256 "${DISTDIR}"/synergy-1.12.0.png qdeskflow.png
		make_desktop_entry qdeskflow Deskflow qdeskflow 'Utility;'
	fi

	insinto /etc
	newins doc/deskflow.conf.example deskflow.conf

	#newman doc/deskflowc.man deskflowc.1
	#newman doc/deskflows.man deskflows.1

	einstalldocs
}

pkg_postinst() {
	use gui && xdg_icon_cache_update
}

pkg_postrm() {
	use gui && xdg_icon_cache_update
}
