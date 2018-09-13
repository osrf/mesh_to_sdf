# Mesh to SDF

Helper scripts to create SDF models using mesh files for visual and collision.

## Usage

Pre-requisites:

* There is 1 mesh file (supported formats: `dae`, `DAE`)
* There is 1 texture file (supported formats: `png`, `PNG`)
* All files are in the same directory
* All files have the same name before the extension

The generated model:

* Uses the texture as both visual and collision
* Is static

For example, your files could be located as follows:

~~~
/home/username/banana/
├── TheBanana.DAE
└── TheBanana.PNG
~~~

The you can run the following command:

    bash mesh_to_sdf.bash -m /home/username/banana/TheBanana\
                          -s /home/username/.gazebo/models\
                           -n "My Banana"

And you'll create the following files:

~~~
/home/username/My Banana
├── materials
│   └── textures
│       └── My Banana.png
├── meshes
│   └── My Banana.dae
├── model.config
└── model.sdf
~~~

## TODO

* Support `jpg` textures
* Support `obj` + `mtl` files
* Add more parameters, such as whether the model is static

