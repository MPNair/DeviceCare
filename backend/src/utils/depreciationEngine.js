/**
 * Smart Depreciation Engine
 * Calculates current market value based on various factors.
 */
const calculateCurrentValue = (gadget, logs) => {
    const { purchasePrice, purchaseDate, conditionScore, category } = gadget;

    // 1. Time-based depreciation (Age)
    const ageInMonths = (new Date() - new Date(purchaseDate)) / (1000 * 60 * 60 * 24 * 30);

    // Category-specific monthly depreciation rates (approximate)
    const monthlyRates = {
        smartphone: 0.03, // 3% per month
        laptop: 0.02,     // 2% per month
        camera: 0.015,    // 1.5% per month
        smartwatch: 0.025,
        console: 0.01,
        other: 0.02
    };

    const normalizedCategory = (category || 'other').toLowerCase();
    const rate = monthlyRates[normalizedCategory] || monthlyRates.other;
    // Ensure purchasePrice defaults to 0 if null/undefined
    let currentValue = (purchasePrice || 0) * Math.pow(1 - rate, ageInMonths);

    // 2. Condition Score impact (score 1-10)
    // 10 = like new, 1 = broken
    // Adjust value: 10/10 = 100%, 5/10 = 70%, 1/10 = 30%
    // Ensure conditionScore defaults to a reasonable value (e.g., 5) if null/undefined
    const effectiveConditionScore = conditionScore != null ? conditionScore : 5; // Default to 5 if missing
    const conditionFactor = 0.3 + (effectiveConditionScore / 10) * 0.7;
    currentValue *= conditionFactor;

    // 3. Maintenance History impact
    // Regular maintenance increases value, frequent repairs might decrease it if not documented as "upgrades"
    const serviceCount = logs.length;
    if (serviceCount > 0) {
        // Bonus for well-maintained devices (max 10% bonus)
        const maintenanceBonus = Math.min(0.1, serviceCount * 0.02);
        currentValue *= (1 + maintenanceBonus);
    }

    // 4. Simulated Market Trend Data
    // Random fluctuation +/- 5% to simulate market trends
    const trendFactor = 0.95 + (Math.random() * 0.1);
    currentValue *= trendFactor;

    return parseFloat(currentValue.toFixed(2));
};

module.exports = { calculateCurrentValue };
