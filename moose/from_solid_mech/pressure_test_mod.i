#
# Pressure Test
#
# This test is designed to compute pressure loads on three faces of a unit cube.
#
# The mesh is composed of one block with a single element.  Symmetry bcs are
#   applied to the faces opposite the pressures.  Poisson's ratio is zero,
#   which makes it trivial to check displacements.
#

[GlobalParams]
  disp_x = disp_x
  disp_y = disp_y
  disp_z = disp_z
[../]

[Mesh]
#  file = 2D-RZ_mesh.e
  type = GeneratedMesh
  dim = 2
  xmin = 0.0
  xmax = 1.0
  ymin = 0.0
  ymax = 1.0
  nx = 1
  ny = 1
[]


[Variables]

  [./disp_x]
    order = FIRST
    family = LAGRANGE
  [../]

  [./disp_y]
    order = FIRST
    family = LAGRANGE
  [../]

[] # Variables

[SolidMechanics]

  [./solid]
    disp_x = disp_x
    disp_y = disp_y
  [../]

[] # SolidMechanics


[BCs]

  [./no_x]
    type = PresetBC
    variable = disp_x
    boundary = left
    value = 0.0
  [../]

  [./no_y]
    type = PresetBC
    variable = disp_y
    boundary = bottom
    value = 0.0
  [../]

  [./Pressure]
    [./Side1]
      boundary = top
      function = '200000*t'
    [../]
  [../]

[] # BCs

[Materials]

  [./stiffStuff]
    type = LinearIsotropicMaterial
    block = 0

    disp_x = disp_x
    disp_y = disp_y

    youngs_modulus = 1e6
    poissons_ratio = 0.0
    #thermal_expansion = 1e-5
  [../]

[] # Materials

[Executioner]

  type = Transient

  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'




  nl_abs_tol = 1e-10

  l_max_its = 20

  start_time = 0.0
  dt = 1.0
  #num_steps = 2
  end_time = 4.0
[] # Executioner

[Outputs]
  output_initial = true
  print_linear_residuals = true
  print_perf_log = true
  [./out]
    type = Exodus
    elemental_as_nodal = true
  [../]
[] # Outputs
