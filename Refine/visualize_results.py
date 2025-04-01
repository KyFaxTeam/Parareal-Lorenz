# filepath: visualize_results.py
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

# --- Configuration ---
INPUT_CSV_FILE = "lorenz_scan_results.csv"
OUTPUT_DIR = "plots"
# Define R values for which to generate histograms (adjust after seeing the bifurcation plot)
HISTOGRAM_R_VALUES = [0.8, 1.5, 2.5] 
# Define a threshold for HUGE values coming from Fortran (adjust if needed)
HUGE_THRESHOLD = 1.0e30 

# --- Helper Functions ---

def clean_huge_values(df, threshold):
    """Replaces values above a threshold (Fortran HUGE) with NaN."""
    # Replace infinities first, then apply threshold check
    df_no_inf = df.replace([np.inf, -np.inf], np.nan)
    return df_no_inf.applymap(lambda x: np.nan if isinstance(x, (int, float)) and abs(x) >= threshold else x)


def plot_bifurcation(df, output_filename):
    """Generates the bifurcation-like plot (<X>_j vs R)."""
    print(f"Generating bifurcation plot: {output_filename}")
    plt.figure(figsize=(12, 7))
    
    # Identify columns containing individual Avg_X_j results
    avg_x_cols = [col for col in df.columns if col.startswith('Avg_X_')]
    if not avg_x_cols:
        print("Error: No 'Avg_X_' columns found in the CSV. Cannot generate bifurcation plot.")
        plt.close()
        return
        
    # Extract R values and the individual X_j results into NumPy arrays for efficiency
    r_vals_all = df['R'].values
    x_j_data = df[avg_x_cols].values # This is now a 2D NumPy array

    # Create lists for plotting points efficiently
    plot_r = []
    plot_x = []
    for i, r_val in enumerate(r_vals_all):
        # Get the row of x_j values, filter out NaNs
        valid_x_j = x_j_data[i, :][~np.isnan(x_j_data[i, :])]
        if len(valid_x_j) > 0:
            plot_r.extend([r_val] * len(valid_x_j))
            plot_x.extend(valid_x_j)

    if not plot_r:
        print("Warning: No valid data points found to plot in bifurcation diagram.")
    else:
        plt.plot(plot_r, plot_x, ',', color='blue', alpha=0.5) # Use ',' for small points
            
    plt.xlabel("Parameter R")
    plt.ylabel("Asymptotic Average Velocity <X>_j")
    plt.title("Bifurcation Diagram for Asymptotic Average Velocity <X>")
    plt.grid(True, linestyle='--', alpha=0.6)
    plt.savefig(output_filename)
    plt.close()
    print("... Bifurcation plot saved.")

def plot_ensemble_stats(df, output_filename):
    """Generates the plot for ensemble average and std dev vs R."""
    print(f"Generating ensemble statistics plot: {output_filename}")
    plt.figure(figsize=(12, 7))
    
    # Ensure required columns exist
    if 'R' not in df.columns or 'Avg_X_Ensemble' not in df.columns or 'StdDev_X_Ensemble' not in df.columns:
        print("Error: Required columns ('R', 'Avg_X_Ensemble', 'StdDev_X_Ensemble') not found.")
        plt.close()
        return
        
    r_values = df['R']
    avg_ensemble = df['Avg_X_Ensemble'].copy() # Work on copies to avoid SettingWithCopyWarning
    std_dev_ensemble = df['StdDev_X_Ensemble'].copy()

    # Handle potential NaNs (where stats couldn't be calculated) before plotting
    valid_mask = ~np.isnan(r_values) & ~np.isnan(avg_ensemble) & ~np.isnan(std_dev_ensemble)
    r_values_valid = r_values[valid_mask]
    avg_ensemble_valid = avg_ensemble[valid_mask]
    std_dev_ensemble_valid = std_dev_ensemble[valid_mask]

    if len(r_values_valid) == 0:
        print("Warning: No valid ensemble data points found to plot.")
        plt.close()
        return

    # Plot average
    plt.plot(r_values_valid, avg_ensemble_valid, 'r-', label='Ensemble Average <X>_R', linewidth=2)
    
    # Plot standard deviation as shaded region around the average
    plt.fill_between(r_values_valid, avg_ensemble_valid - std_dev_ensemble_valid, avg_ensemble_valid + std_dev_ensemble_valid, 
                     color='red', alpha=0.2, label='± Std Dev σ_X(R)')
                     
    # Alternatively, plot std dev as a separate line:
    # plt.plot(r_values_valid, std_dev_ensemble_valid, 'g--', label='Std Dev σ_X(R)', linewidth=1.5)

    plt.xlabel("Parameter R")
    plt.ylabel("Value")
    plt.title("Ensemble Average and Standard Deviation of <X> vs R")
    plt.legend()
    plt.grid(True, linestyle='--', alpha=0.6)
    plt.savefig(output_filename)
    plt.close()
    print("... Ensemble statistics plot saved.")

def plot_histograms(df, r_values_to_plot, output_dir):
    """Generates histograms of <X>_j for specific R values."""
    print(f"Generating histograms for R values: {r_values_to_plot}")
    avg_x_cols = [col for col in df.columns if col.startswith('Avg_X_')]
    if not avg_x_cols:
        print("Error: No 'Avg_X_' columns found. Cannot generate histograms.")
        return

    for r_target in r_values_to_plot:
        # Find the row index closest to the target R value
        closest_idx = (df['R'] - r_target).abs().idxmin()
        row = df.loc[[closest_idx]] # Use double brackets to keep it as a DataFrame row
        
        r_actual = row['R'].iloc[0]
        # Extract the Avg_X_j values for this row, convert to NumPy, drop NaNs
        x_j_values = row[avg_x_cols].iloc[0].values 
        x_j_values = x_j_values[~np.isnan(x_j_values)] # Filter NaNs
        
        if len(x_j_values) == 0:
             print(f"  Warning: No valid <X>_j data found for R ≈ {r_actual:.3f} (target {r_target}). Skipping histogram.")
             continue

        plt.figure(figsize=(8, 5))
        plt.hist(x_j_values, bins=15, density=True, alpha=0.7, color='purple') # Adjust bins as needed
        plt.xlabel("Asymptotic Average Velocity <X>_j")
        plt.ylabel("Probability Density")
        plt.title(f"Distribution of <X>_j for R ≈ {r_actual:.3f} (N_valid = {len(x_j_values)})")
        plt.grid(True, linestyle='--', alpha=0.6)
        
        # Sanitize filename
        r_str = f"{r_actual:.3f}".replace('.', '_')
        output_filename = os.path.join(output_dir, f"histogram_R_{r_str}.png")
        plt.savefig(output_filename)
        plt.close()
        print(f"... Histogram for R ≈ {r_actual:.3f} saved to {output_filename}")

# --- Main Execution ---
if __name__ == "__main__":
    print("--- Starting Visualization Script ---")
    
    # Create output directory if it doesn't exist
    if not os.path.exists(OUTPUT_DIR):
        try:
            os.makedirs(OUTPUT_DIR)
            print(f"Created output directory: {OUTPUT_DIR}")
        except OSError as e:
            print(f"Error creating output directory '{OUTPUT_DIR}': {e}")
            exit()

    # Check if input file exists
    if not os.path.isfile(INPUT_CSV_FILE):
        print(f"Error: Input CSV file not found: {INPUT_CSV_FILE}")
        print("Please run the Fortran simulation first to generate the results.")
        exit()
        
    print(f"Loading data from: {INPUT_CSV_FILE}")
    try:
        # Load data
        df = pd.read_csv(INPUT_CSV_FILE)
        
        # Clean data (replace HUGE values with NaN)
        df_cleaned = clean_huge_values(df, HUGE_THRESHOLD)
        
        # Generate plots
        plot_bifurcation(df_cleaned, os.path.join(OUTPUT_DIR, "bifurcation_plot.png"))
        plot_ensemble_stats(df_cleaned, os.path.join(OUTPUT_DIR, "ensemble_stats_plot.png"))
        plot_histograms(df_cleaned, HISTOGRAM_R_VALUES, OUTPUT_DIR)
        
        print("--- Visualization Script Finished ---")
        
    except FileNotFoundError:
        print(f"Error: Could not find the input file '{INPUT_CSV_FILE}'.")
    except pd.errors.EmptyDataError:
         print(f"Error: The input file '{INPUT_CSV_FILE}' is empty.")
    except KeyError as e:
        print(f"Error: Missing expected column in CSV file: {e}")
    except Exception as e:
        print(f"An unexpected error occurred during visualization: {e}")