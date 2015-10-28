/****************************************************************/
/* MOOSE - Multiphysics Object Oriented Simulation Environment  */
/*                                                              */
/*          All contents are licensed under LGPL V2.1           */
/*             See LICENSE for full restrictions                */
/****************************************************************/
#include "ComputeMultiPlasticityStress.h"
#include "MultiPlasticityDebugger.h"

#include "MooseException.h"
#include "RotationMatrix.h" // for rotVecToZ **might not need now

template <>
Input Parameters validParameters<ComputeIsotropicSinglePlasticity>()
{
  InputParameters params = validParams<ComputeStressBase>();
  params += validParams<MultiPlasticityDebugger>();
  params += validParams<ComputeMultiPlasticityStress>();
  params.addClassDescription("Class for single-surface small-strain plasticity (isotropic elasticity tensor, radial return mapping, J2)");
  return params;
}

ComputeIsotropicSinglePlasticity::ComputeIsotropicSinglePlasticity(const Input Parameters & parameters) :
    ComputeStressBase(parameters),
    MultiPlasticityDebugger(parameters),
    ComputeMultiPlasticityStress(parameters)
{
    // check to see if elasticity tensor is isotropic
    bool radialReturnMap = false;
    //if statement to account for user-defined isotropic elasticity (no fill method)\
    //set to true for now
    radialReturnMap = true;

    // error if incorrect material
    if (!radialReturnMap)
      mooseError("Cannot use radial return mapping if the elasticity tensor is not isotropic.")
}

// copied from SM/ReturnMappingModel
void
ReturnMappingModel::computeStress( const Elem & current_elem,
                                   unsigned qp, const SymmElasticityTensor & elasticityTensor,
                                   const SymmTensor & stress_old, SymmTensor & strain_increment,
                                   SymmTensor & stress_new )
{
  // Given the stretching, compute the stress increment and add it to the old stress. Also update the creep strain
  // stress = stressOld + stressIncrement
  if (_t_step == 0) return;

  stress_new = elasticityTensor * strain_increment;
  stress_new += stress_old;

  SymmTensor inelastic_strain_increment;
  computeStress( current_elem, qp, elasticityTensor, stress_old,
                 strain_increment, stress_new, inelastic_strain_increment );

}

void
ComputeIsotropicSinglePlasticity::computeStress( const Elem & /*current_elem*/, unsigned qp,
                                   const SymmElasticityTensor & elasticityTensor,
                                   const SymmTensor & stress_old,
                                   SymmTensor & strain_increment,
                                   SymmTensor & stress_new,
                                   SymmTensor & inelastic_strain_increment )
{

  // compute deviatoric trial stress
  SymmTensor dev_trial_stress(stress_new);
  dev_trial_stress.addDiag( -dev_trial_stress.trace()/3.0 );

  // compute effective trial stress
  Real dts_squared = dev_trial_stress.doubleContraction(dev_trial_stress);
  Real effective_trial_stress = std::sqrt(1.5 * dts_squared);

  computeStressInitialize(qp, effective_trial_stress, elasticityTensor);

  // Use Newton sub-iteration to determine inelastic strain increment

  Real scalar = 0;
  unsigned int it = 0;
  Real residual = 10;
  Real norm_residual = 10;
  Real first_norm_residual = 10;

  std::stringstream iter_output;

  while (it < _max_its &&
        norm_residual > _absolute_tolerance &&
        (norm_residual/first_norm_residual) > _relative_tolerance)
  {
    // iterationInitialize( qp, scalar );
    // function above doesn't appear to do anything

    residual = computeResidual(qp, effective_trial_stress, scalar);
    norm_residual = std::abs(residual);
    if (it == 0)
    {
      first_norm_residual = norm_residual;
      if (first_norm_residual == 0)
      {
        first_norm_residual = 1;
      }
    }

    scalar -= residual / computeDerivative(qp, effective_trial_stress, scalar);

    iterationFinalize(qp, scalar);

    ++it;
  }

  if (it == _max_its &&
     norm_residual > _absolute_tolerance &&
     (norm_residual/first_norm_residual) > _relative_tolerance)
  {
    if (_output_iteration_info_on_error)
    mooseError("Max sub-newton iteration hit during nonlinear constitutive model solve!");
  }

  // compute inelastic and elastic strain increments (avoid potential divide by zero - how should this be done)?
  if (effective_trial_stress < 0.01)
  {
    effective_trial_stress = 0.01;
  }

  inelastic_strain_increment = dev_trial_stress;
  inelastic_strain_increment *= (1.5*scalar/effective_trial_stress);

  strain_increment -= inelastic_strain_increment;

  // compute stress increment
  stress_new = elasticityTensor * strain_increment;

  // update stress
  stress_new += stress_old;

  // update plastic strain
  _plastic_strain[qp] += plasticStrainIncrement;
}

Real
ComputeIsotropicSinglePlasticity::computeDerivative(unsigned int /*qp*/, Real /*effectiveTrialStress*/, Real /*scalar*/)
{
  Real derivative(1);
  if (_yield_condition > 0)
  {
    derivative = -3 * _shear_modulus - _hardening_slope;
  }
  return derivative;
}

void
ComputeIsotropicSinglePlasticity::iterationFinalize(unsigned qp, Real scalar)
{
  _hardening_variable[qp] = _hardening_variable_old[qp] + (_hardening_slope * scalar);
  if (_scalar_plastic_strain)
  {
    (*_scalar_plastic_strain)[qp] = (*_scalar_plastic_strain_old)[qp] + scalar;
  }
}

void
ComputeIsotropicSinglePlasticity::computeStressInitialize(unsigned qp, Real effectiveTrialStress, const SymmElasticTensor & elasticityTensor)
{
  const SymmIsotropicElasticityTensor * eT = dynamic_cast<const SymmIsotropicElasticityTensor*>(&elasticityTensor);
  if (!eT)
  {
    mooseError("Isotropic elasticity return mapping requires a symmetric isotropic elasticity tensor");
    // not sure if true; isotropic yes, but maybe not symmetric
  }
  _shear_modulus = eT->shearModulus();
  _yield_condition = effectiveTrialStress - _hardening_variable_old[qp] - _yield_stress;
  _hardening_variable[qp] = _hardening_variable_old[qp];
  _plastic_strain[qp] = _plastic_strain_old[qp];
}
