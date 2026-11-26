### Power analysis using "mixedpower"
library(mixedpower)
library(lmerTest)

full_model <- glmer(ppt_correct ~ grouping * comp_hint * perf + perf*trial_c +
                        (1 + trial_c | participant) + 
                        (1 | demo_img), 
                      family = "binomial", 
                      data = dat,
                      control = glmerControl(optimizer = "bobyqa"))

perf_model <- glmer(ppt_correct ~ perf * trial_c + 
                        (1 | participant) + 
                        (1 | demo_img), 
                      family = "binomial", 
                      data = dat,
                      control = glmerControl(optimizer = "bobyqa"))

group_model <- glmer(ppt_correct ~ grouping * trial_c + 
                        (1 + trial_c | participant) + 
                        (1 | demo_img), 
                      family = "binomial", 
                      data = dat,
                      control = glmerControl(optimizer = "bobyqa"))

iq_model <- glmer(ppt_correct ~ comp_hint * trial_c + 
                        (1 + trial_c | participant) + 
                        (1 | demo_img), 
                      family = "binomial", 
                      data = dat,
                      control = glmerControl(optimizer = "bobyqa"))

model <- full_model #change model accordingly.
data <- dat #Use the same environment with the main analysis.
fixed_effects <- c("perf", "trial_c")
simvar <- "participant_num" #random effect simulation

steps <- c(10, 20, 30, 40, 50)
critical_value <- 2
n_sim <- 1000

power <- mixedpower(model = model, data = dat,
                    fixed_effects = fixed_effects,
                    simvar = simvar, steps = steps,
                    critical_value = critical_value, n_sim = n_sim)
power

write.csv(power, "power_1000.csv")

#SESOI - using values from previous research
fixef(full_model)["perfsuperb:trial_c"] <- 0.487 
model_extended <- extend(full_model, along="participant", n=100)
sim_curve <- powerCurve(model_extended, test = simr::fixed("perfsuperb:trial_c", "z"), along = "participant", breaks = c(30, 50, 70, 90), nsim = 100)

print(sim_curve) 
plot(sim_curve) #30~90 까지 다 100.