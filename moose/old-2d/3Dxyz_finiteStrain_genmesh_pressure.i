# Considers the mechanics solution for a thick spherical shell that is uniformly
# pressurized on the inner and outer surfaces, using 2D axisymmetric geometry.
#
# From Roark (Formulas for Stress and Strain, McGraw-Hill, 1975), the radially-dependent
# circumferential stress in a uniformly pressurized thick spherical shell is given by:
#
# S(r) = [ Pi[ri^3(2r^3+ro^3)] - Po[ro^3(2r^3+ri^3)] ] / [2r^3(ro^3-ri^3)]
#
#   where:
#          Pi = inner pressure
#          Po = outer pressure
#          ri = inner radius
#          ro = outer radius
#
# The tests assume an inner and outer radii of 5 and 10, with internal and external
# pressures of 100000 and 200000, respectively. The resulting compressive tangential
# stress is largest at the inner wall and, from the above equation, has a value
# of -271429.
#
# RESULTS are below. Since stresses are average element values, values for the
# edge element and one-element-in are used to extrapolate the stress to the
# inner surface. The vesrion of the tests that are checked use the coarsest meshes.
#
#  Mesh    Radial elem   S(edge elem)  S(one elem in)  S(extrap to surf)
# 1D-SPH
# 2D-RZ        12 (x10)    -265004      -254665        -270174
#  3D          12 (6x6)    -261880      -252811        -266415
#
# 1D-SPH
# 2D-RZ        48 (x10)    -269853      -266710        -271425
#  3D          48 (10x10)  -268522      -265653        -269957
#
# The numerical solution converges to the analytical solution as the mesh is
# refined.

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

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

#[Problem]
#  coord_type = RZ
#[]

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
[]

[Kernels]
  [./TensorMechanics]
  [../]
[]

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
  [./stress_yy]
    type = RankTwoAux #only computing equiv zz (theta-theta) stress
    rank_two_tensor = stress
    index_i = 1
    index_j = 1
    variable = stress_yy
    execute_on = timestep_end
  [../]
  [./strain_yy]
    type = RankTwoAux
    rank_two_tensor = elastic_strain
    index_i = 1
    index_j = 1
    variable = strain_yy
    execute_on = timestep_end
[../]
[]

[Materials]
  [./elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1e6
    poissons_ratio = 0.3
    block = 0
  [../]

  [./finite_strain]
    type = ComputeFiniteStrain
    block = 0
  [../]

  [./elastic_stress]
    type = ComputeFiniteStrainElasticStress
    block = 0
  [../]
[]

[BCs]
  [./no_disp_x_left]
    type = PresetBC #changed to PresetBC from DirichletBC
    variable = disp_x
    boundary = left
    value = 0.0
  [../]
#  [./no_disp_x_right]
#    type = PresetBC
#    variable = disp_x
#    boundary = right
#    value = 0.0
#  [../]
  [./no_disp_y_bottom]
    type = PresetBC
    variable = disp_y
    boundary = bottom
    value = 0.0
  [../]
  [./no_disp_z_back]
    type = PresetBC
    variable = disp_z
    boundary = back
    value = 0.0
  [../]
  [./no_disp_z_front]
    type = PresetBC
    variable = disp_z
    #boundary = yzero
    boundary = front
    value = 0.0
  [../]
#  [./y_top]
#    type = FunctionPresetBC
#    variable = disp_y
#    boundary = top
#    function = '-0.2*t'
#  [../]
  [./PressureTM]
    [./top]
      boundary = top
      function = '200000*t'
      disp_x = disp_x
      disp_y = disp_y
      disp_z = disp_z
    [../]
  [../]
[]

[Debug]
    show_var_residual_norms = true
[]

[Executioner]
  type = Transient

  petsc_options_iname = '-ksp_gmres_restart -pc_type -pc_hypre_type -pc_hypre_boomeramg_max_iter'
  petsc_options_value = '  201               hypre    boomeramg      10'

  line_search = 'none'

  #Preconditioned JFNK (default)
  solve_type = 'PJFNK'

  nl_rel_tol = 5e-9
  nl_abs_tol = 1e-10
  nl_max_its = 15

  l_tol = 1e-3
  l_max_its = 50

  start_time = 0.0
  end_time = 4
#  num_steps = 1000
  dt = 0.1

  #dtmax = 1
  #dtmin = 0.01

#  [./TimeStepper]
#    type = IterationAdaptiveDT
#    dt = 1
#    optimal_iterations = 6
#    iteration_window = 0.4
#    linear_iteration_ratio = 100
#  [../]

#  [./Predictor]
#    type = SimplePredictor
#    scale = 1.0
#  [../]

[]

[Postprocessors]
  [./dt]
    type = TimestepSize
  [../]
  [./strain]
    type = ElementAverageValue
    variable = strain_yy
  [../]
  [./stress]
    type = ElementAverageValue
    variable = stress_yy
  [../]
[]

[Outputs]
  #file_base = 2D-RZ_finiteStrain_test_out
  output_on = 'timestep_end'
  output_initial = true
  exodus = true
  csv = true
  print_linear_residuals = true
  print_perf_log = true
  [./console]
    type = Console
    perf_log = true
    output_on = 'initial timestep_end failed nonlinear'
  [../]
[]
