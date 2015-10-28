#
# Pressure Test --- ignore, modified input file
#
# This test is designed to compute pressure loads on three faces of a unit cube.
#
# The mesh is composed of one block with a single element.  Symmetry bcs are
#   applied to the faces opposite the pressures.  Poisson's ratio is zero,
#   which makes it trivial to check displacements.
#


[Mesh]
#  file = 2D-RZ_mesh.e
  type = GeneratedMesh
  dim = 3
  xmin = 0.0
  xmax = 1.0
  ymin = 0.0
  ymax = 1.0
  zmin = 0.0
  zmax = 1.0
  nx = 1
  ny = 1
  nz = 1
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
  [./disp_z]
    order = FIRST
    family = LAGRANGE
  [../]
[] # Variables

[AuxVariables]
  [./stress_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./strain_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./stress]
    type = MaterialTensorAux
    tensor = stress
    variable = stress_yy
    index = 1
  [../]
  [./strain]
    type = MaterialTensorAux
    tensor = total_strain
    variable = strain_yy
    index = 1
  [../]
[]


[SolidMechanics]

  [./solid]
    disp_x = disp_x
    disp_y = disp_y
    disp_z = disp_z
  [../]

[] # SolidMechanics


[BCs]
  [./no_x_left]
    type = PresetBC
    variable = disp_x
    boundary = left
    value = 0.0
  [../]
  [./no_x_right]
    type = PresetBC
    variable = disp_x
    boundary = right
    value = 0.0
  [../]
  [./no_y_bottom]
    type = PresetBC
    variable = disp_y
    boundary = bottom
    value = 0.0
  [../]
  [./no_z_front]
    type = PresetBC
    variable = disp_z
    boundary = front
    value = 0.0
  [../]
  [./no_x_back]
    type = PresetBC
    variable = disp_z
    boundary = back
    value = 0.0
  [../]
#  [./Pressure]
#    [./Side1]
#      boundary = top
#      function = '200000*t'
#    [../]
#  [../]
  [./y_top]
    type = FunctionPresetBC
    variable = disp_y
    boundary = top
    function = '-0.2*t'
  [../]
[] # BCs

[Materials]

  [./stiffStuff]
    #type = LinearIsotropicMaterial
    type = Elastic
    block = 0
    formulation = NonlinearPlaneStrain
    #formulation = Linear

    disp_x = disp_x
    disp_y = disp_y

    youngs_modulus = 1e6
    poissons_ratio = 0.3
    #thermal_expansion = 1e-5
  [../]

[] # Materials

[Postprocessors]
  [./strain]
    type = ElementAverageValue
    variable = strain_yy
  [../]
  [./stress]
    type = ElementAverageValue
    variable = stress_yy
  [../]
[]

[Executioner]

  type = Transient

  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'




  nl_abs_tol = 1e-10

  l_max_its = 20

  start_time = 0.0
  dt = 1
  #num_steps = 2
  end_time = 4.0
[] # Executioner

[Outputs]
  output_initial = true
  print_linear_residuals = true
  print_perf_log = true
  csv = true
  [./out]
    type = Exodus
    elemental_as_nodal = true
  [../]
[] # Outputs
