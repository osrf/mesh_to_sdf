#!/bin/bash

usage()
{
cat << EOF
Create SDF models from mesh and texture files.

EXAMPLE

  bash mesh_to_sdf.bash -m <path>/my_mesh -s ~/.gazebo/models -n "My Model"

OPTIONS:
   -h      Show this message
   -m      Path to mesh files, up to the extension.
           All files must have the same name.
           For example, for "/home/banana.dae" and "/home/banana.png" use
           "/home/banana".
   -s      Path to save resulting SDF model
   -n      Model name, this will be used to name paths, files and the model itself.
           May contain spaces.
EOF
exit
}

# Formatting
ERROR="\e[1m\e[31m"
MSG="\e[33m"
SUMMARY_PROP="\e[1m\e[32m"
SUMMARY_VALUE="\e[32m"
RESET="\e[0m\e[39m"

# Inputs
MESH=""
SDF=""
NAME=""

GetOpts()
{
  argv=()
  while [ $# -gt 0 ]
  do
    opt=$1
    shift
    case ${opt} in
        -m)
          if [ $# -eq 0 -o "${1:0:1}" = "-" ]
          then
            echo -e $ERROR"Specify the path to the meshes with -m"$RESET
          else
            MESH="$1"
          fi
          shift
          ;;
        -s)
          if [ $# -eq 0 -o "${1:0:1}" = "-" ]
          then
            echo -e $ERROR"Specify the path to the SDF with -s"$RESET
          else
            SDF="$1"
          fi
          shift
          ;;
        -n)
          if [ $# -eq 0 -o "${1:0:1}" = "-" ]
          then
            echo -e $ERROR"Specify the model name"$RESET
          else
            NAME="$1"
          fi
          shift
          ;;
        *)
          usage
          argv+=(${opt})
          ;;
    esac
  done
}

GetOpts "$@"

if [ "$MESH" == "" ] || [ "$SDF" == "" ] || [ "$NAME" == "" ]
then
  echo -e $ERROR"Aborting: one or more options are missing."$RESET
  usage
  exit 1
fi

ROOT=$SDF/$NAME
MESHES=$ROOT/meshes
TEXTURES=$ROOT/materials/textures

echo -e $SUMMARY_PROP"Options:"$RESET
echo -e $SUMMARY_PROP"    -Mesh files:        "$RESET$SUMMARY_VALUE $MESH".*" $RESET
echo -e $SUMMARY_PROP"    -Model destination: "$RESET$SUMMARY_VALUE $ROOT $RESET
read -r -p "Does that look right? [y/N] " response

response=${response,,}
if [[ "$response" =~ ^(no|n)$ ]]
then
  exit 1
fi

# Check that mesh files exist
DAE=$MESH.DAE
echo -e $MSG"-Checking "$DAE"..."$RESET
if [[ ! -e $DAE ]]; then
  DAE=$MESH.dae
  if [[ ! -e $DAE ]]; then
    echo -e $ERROR"Missing mesh ["$DAE"]."$RESET
    exit 1
  fi
fi

PNG=$MESH.PNG
echo -e $MSG"-Checking "$PNG"..."$RESET
if [[ ! -e $PNG ]]; then
  PNG=$MESH.png
  if [[ ! -e $PNG ]]; then
    echo -e $ERROR"Missing texture ["$PNG"]."$RESET
    exit 1
  fi
fi

# Create destination directories
echo -e $MSG"-Creating "$ROOT"..."$RESET
if [[ ! -e $ROOT ]]; then
  mkdir -p "$ROOT"
else
  echo -e $ERROR"Failed to create "$ROOT\
       ". Make sure the destination directory doesn't exist."$RESET
  exit 1
fi

echo -e $MSG"-Creating "$MESHES"..."$RESET
mkdir -p "$MESHES"

echo -e $MSG"-Creating "$TEXTURES"..."$RESET
mkdir -p "$TEXTURES"

# Copy meshes
echo -e $MSG"-Copying "$DAE" to \n         "$MESHES/$NAME.dae"..."$RESET
cp "$DAE" "$MESHES/$NAME.dae"
if [ $? -ne 0 ]; then
  echo -e $ERROR"Failed to copy. "$RESET
  exit 1
fi

echo -e $MSG"-Copying "$PNG" to \n         "$TEXTURES/$NAME.png"..."$RESET
cp "$PNG" "$TEXTURES/$NAME.png"
if [ $? -ne 0 ]; then
  echo -e $ERROR"Failed to copy. "$RESET
  exit 1
fi

# Fix texture paths
echo -e $MSG"-Fixing texture paths..."$RESET
sed -i "s/<init_from>.*<\/init_from>/<init_from>$NAME.png<\/init_from>/g" "$MESHES/$NAME.dae"
if [ $? -ne 0 ]; then
  echo -e $ERROR"Failed to set texture paths. "$RESET
  exit 1
fi

# model.config
echo -e $MSG"-Creating model.config..."$RESET

echo "
<?xml version='1.0'?>
<model>
  <name>"$NAME"</name>
  <version>1.0</version>
  <sdf version='1.6'>model.sdf</sdf>

  <description>
    Generated with mesh_to_sdf
    https://bitbucket.org/osrf/mesh_to_sdf
  </description>
</model>
    " > "$ROOT/model.config"

# model.sdf
echo -e $MSG"-Creating model.sdf..."$RESET

  echo "
<?xml version='1.0' ?>
<sdf version='1.6'>
  <model name='"$NAME"'>
    <static>true</static>
    <link name='link'>
      <collision name='collision'>
        <geometry>
          <mesh>
            <uri>model://"$NAME"/meshes/"$NAME".dae</uri>
          </mesh>
        </geometry>
      </collision>
      <visual name='visual'>
        <geometry>
          <mesh>
            <uri>model://"$NAME"/meshes/"$NAME".dae</uri>
          </mesh>
        </geometry>
      </visual>
    </link>
  </model>
</sdf>
    " >> "$ROOT/model.sdf"

echo -e $SUMMARY_PROP"Done!"$RESET

