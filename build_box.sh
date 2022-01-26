#!/bin/sh

STREAM="stable"
ARCH="x86_64"
BUILD_DIR=".build"
BOX=$1

build_box() {
    echo "Building Fedora CoreOS box: $BOX ..."
    VERSION=$(curl -s "https://builds.coreos.fedoraproject.org/prod/streams/${STREAM}/builds/builds.json" | \
	jq -r --arg arch "$ARCH" 'first(.builds[] | select(.arches[] | contains($arch))) | .id // empty')
    URL="https://builds.coreos.fedoraproject.org/prod/streams/$STREAM/builds/$VERSION/$ARCH/fedora-coreos-$VERSION-qemu.$ARCH.qcow2.xz"
    echo $URL
    mkdir -p $BUILD_DIR
    curl -SL $URL | xz -d -c > $BUILD_DIR/box.img
    cat ./box_metadata_libvirt.json > $BUILD_DIR/metadata.json
    cat ./box_vagrantfile_libvirt > $BUILD_DIR/Vagrantfile
    tar czvf $BUILD_DIR/$BOX -C $BUILD_DIR box.img metadata.json Vagrantfile
    jq --arg version $VERSION --arg url $BUILD_DIR/$BOX --arg shasum $(sha256sum $BUILD_DIR/$BOX | cut -d " " -f 1) '
           .versions[0].version |= $version
           |.versions[0].providers[0].checksum |= $shasum
           |.versions[0].providers[0].url |= $url
           |.versions[0].providers[0].checksum_type |= "sha256"' ./info-template.json > $BUILD_DIR/$BOX.json    
    vagrant box add --force $BUILD_DIR/$BOX.json
    echo "Done."
}

[ -f "$BUILD_DIR/$BOX" ] || build_box

