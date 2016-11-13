#version 450

#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable

struct Particle
{
    vec2 pos;
    vec2 vel;
};

// LOOK: These bindings correspond to the DescriptorSetLayouts and
// the DescriptorSets from prepareCompute()!

// Binding 0 : Particle storage buffer (read)
layout(std140, binding = 0) buffer ParticlesA
{
   Particle particlesA[ ];
};

// Binding 1 : Particle storage buffer (write)
layout(std140, binding = 1) buffer ParticlesB
{
   Particle particlesB[ ];
};

layout (local_size_x = 16, local_size_y = 16) in;

// LOOK: rule weights and distances, as well as particle count, based off uniforms.
// The deltaT here has to be updated every frame to account for changes in
// frame rate.
layout (binding = 2) uniform UBO
{
    float deltaT;
    float rule1Distance;
    float rule2Distance;
    float rule3Distance;
    float rule1Scale;
    float rule2Scale;
    float rule3Scale;
    int particleCount;
} ubo;

void main()
{
    // LOOK: This is very similar to a CUDA kernel.
    // Right now, the compute shader only advects the particles with their
    // velocity and handles wrap-around.
    // DONE: implement flocking behavior.

    // Current SSBO index
    uint index = gl_GlobalInvocationID.x;
    // Don't try to write beyond particle count
    if (index >= ubo.particleCount)
        return;

    // Read position and velocity
    vec2 vPos = particlesA[index].pos.xy;
    vec2 vVel = particlesA[index].vel.xy;

    vec2 delta_vel = vec2(0.0);
    vec2 rule1_neighbor_pos_sum = vec2(0.0);
    float rule1_neighbor_count = 0.0;
    vec2 rule2_total_offset = vec2(0.0);
    vec2 rule3_neighbor_vel_sum = vec2(0.0);
    float rule3_neighbor_count = 0.0;

    vec2 current_offset;
    float current_distance;
    for (int i = 0; i < ubo.particleCount; i++)
    {
        if (i == index) continue;

        current_offset = particlesA[i].pos.xy - vPos;
        current_distance = length(current_offset);

        // Rule 1: Get neighbor position sum and neighbor count for rule1
        if (current_distance < ubo.rule1Distance)
        {
            rule1_neighbor_pos_sum += particlesA[i].pos.xy;
            rule1_neighbor_count += 1.0;
        }
        // Rule 2: Calculate offset for rule 2
        if (current_distance < ubo.rule2Distance)
        {
            rule2_total_offset -= current_offset;
        }
        // Rule 3: Get velocity sum and neighbor count for rule 3
        if (current_distance < ubo.rule3Distance)
        {
            rule3_neighbor_vel_sum += particlesA[i].vel.xy;
            rule3_neighbor_count += 1.0;
        }

    }

    // Rule 1: boids fly towards their local perceived center of mass, which excludes themselves
    if (rule1_neighbor_count > 0.0)
    {
        delta_vel += ubo.rule1Scale * ((rule1_neighbor_pos_sum / rule1_neighbor_count) - vPos);
    }

    // Rule 2: boids try to stay a distance d away from each other
    delta_vel += ubo.rule2Scale *  rule2_total_offset;

    // Rule 3: boids try to match the speed of surrounding boids
    if (rule3_neighbor_count > 0.0)
    {
        delta_vel += ubo.rule3Scale * (rule3_neighbor_vel_sum / rule3_neighbor_count); // said this looks better using the parameters
        //delta_vel += ubo.rule3Scale * ((rule3_neighbor_vel_sum / rule3_neighbor_count) - vVel);
    }

    vVel += delta_vel;

    // clamp velocity for a more pleasing simulation.
    vVel = normalize(vVel) * clamp(length(vVel), 0.0, 0.1);

    // kinematic update
    vPos += vVel * ubo.deltaT;

    // Wrap around boundary
    if (vPos.x < -1.0) vPos.x = 1.0;
    if (vPos.x > 1.0) vPos.x = -1.0;
    if (vPos.y < -1.0) vPos.y = 1.0;
    if (vPos.y > 1.0) vPos.y = -1.0;

    particlesB[index].pos.xy = vPos;

    // Write back
    particlesB[index].vel.xy = vVel;
}
