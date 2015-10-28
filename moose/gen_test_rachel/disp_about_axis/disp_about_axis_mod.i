[GlobalParams]
  order = FIRST
  family = LAGRANGE
  disp_x = disp_x
  disp_y = disp_y
  disp_z = disp_z
[]

[Mesh]
  file = cylinder.e
  displacements = 'disp_x disp_y disp_z'
[]


[Variables]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
  [./disp_z]
  [../]
[]


[AuxVariables]
  [./stress_xx]
    # stress aux variables are defined for output; this is a way to get integration point variables to the output file
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./stress_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./stress_zz]
    order = CONSTANT
    family = MONOMIAL
  [../]
#  [./vonmises] don't know equiv tensor name in tensormechs
#    order = CONSTANT
#    family = MONOMIAL
#  [../]
[]

[Functions]
  [./rampConstant]
    type = PiecewiseLinear
    x = '0. 1. 2.'
    y = '0. 0.5 1.'
    scale_factor = 10
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x disp_y disp_z'
    #removed solidmechs block and added tensormechs kernel
  [../]
[]

[AuxKernels]
  [./stress_xx]
    type = RankTwoAux
    #removed MaterialTensorAux stress auxkernels and replaced with RankTwoAux
    rank_two_tensor = stress
    variable = stress_xx
    index_j = 0
    index_i = 0
  [../]
  [./stress_xy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_xy
    index_j = 1
    index_i = 0
  [../]
  [./stress_yy]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_yy
    index_j = 1
    index_i = 1
  [../]
  [./stress_zz]
    type = RankTwoAux
    rank_two_tensor = stress
    variable = stress_zz
    index_j = 2
    index_i = 2
  [../]
#  [./vonmises] don't know equiv in tensormechs
#    type = MaterialTensorAux
#    tensor = stress
#    variable = vonmises
#    quantity = vonmises
#    execute_on = timestep_end
#  [../]
[]

[BCs]

  [./bottom_x]
    type = PresetBC #changed three from DirichletBC
    variable = disp_x
    boundary = 1
    value = 0.0
  [../]
  [./bottom_y]
    type = PresetBC
    variable = disp_y
    boundary = 1
    value = 0.0
  [../]
  [./bottom_z]
    type = PresetBC
    variable = disp_z
    boundary = 1
    value = 0.0
  [../]

  [./DisplacementAboutAxis]
    [./top]
      boundary = 2
      function = rampConstant
      angle_units = degrees
      axis_origin = '10 10 10'
      axis_direction = '0 -0.70710678 0.70710678'
      #error returned:
      #*** ERROR *** -- changed from BC type to action, same error
      #The following required parameters are missing:
      #BCs/DisplacementAboutAxis/boundary
      #	Doc String: "The list of boundary IDs from the mesh where this boundary condition applies"
      #BCs/DisplacementAboutAxis/type
      #	Doc String: "A string representing the Moose Object that will be built by this Action"
      #BCs/DisplacementAboutAxis/variable
      #	Doc String: "The name of the variable that this boundary condition applies to"
    [../]
  [../]
[] # BCs

[Materials]
#  [./stiffStuff]
#    type = Elastic #need to change to tensormech material
#    block = 1
#
#    disp_x = disp_x
#    disp_y = disp_y
#    disp_z = disp_z
#
#    youngs_modulus = 207000
#    poissons_ratio = 0.3
#  [../]

  [./elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 207000
    poissons_ratio = 0.3
    block = 1
  [../]
  [./finite_strain_norz]
    type = ComputeFiniteStrain
    block = 1
  [../]
  [./_elastic_stress]
    type = ComputeFiniteStrainElasticStress
    block = 1
  [../]
[]
[]


[Executioner]

  type = Transient
  # Two sets of linesearch options are for petsc 3.1 and 3.3 respectively

  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'


  petsc_options = '-snes_ksp_ew'
  petsc_options_iname = '-ksp_gmres_restart'
  petsc_options_value = '101'


  line_search = 'none'

  l_max_its = 50
  nl_max_its = 20
  nl_rel_tol = 1e-12
  l_tol = 1e-2

  start_time = 0.0
  dt = 1

  end_time = 2
  num_steps = 2

[]

[Postprocessors] #all in framework so no changes needed
  [./_dt]
    type = TimestepSize
  [../]

  [./nl_its]
    type = NumNonlinearIterations
  [../]

  [./lin_its]
    type = NumLinearIterations
  [../]

[]


[Outputs]
  #file_base = disp_about_axis_out
  output_initial = true
  exodus = true
  print_linear_residuals = true
  print_perf_log = true
[]
