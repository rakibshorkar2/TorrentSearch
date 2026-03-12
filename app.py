import streamlit as st
import requests
import pandas as pd
from datetime import datetime
import urllib.parse
import time

# --- PAGE CONFIGURATION ---
st.set_page_config(page_title="TorrentX Nexus", page_icon="🌀", layout="wide")

# --- CSS INJECTION (Animations & UI) ---
st.markdown("""
<style>
    /* Gradient Animated Text */
    @keyframes gradient { 0% {background-position: 0% 50%;} 50% {background-position: 100% 50%;} 100% {background-position: 0% 50%;} }
    .title-anim { 
        background: linear-gradient(-45deg, #00C9FF, #92FE9D, #fc00ff, #00dbde); 
        background-size: 400% 400%; animation: gradient 5s ease infinite; 
        -webkit-background-clip: text; -webkit-text-fill-color: transparent; 
        font-size: 3.5rem; font-weight: 900; text-align: center; margin-bottom: 10px;
    }
    
    /* Card Animations */
    @keyframes fadeIn { from { opacity: 0; transform: translateY(15px); } to { opacity: 1; transform: translateY(0); } }
    div[data-testid="stVerticalBlock"] > div > div[data-testid="stVerticalBlock"] {
        animation: fadeIn 0.6s ease-out forwards;
    }
    
    /* Metric Card Styling */
    div[data-testid="metric-container"] {
        background-color: rgba(128, 128, 128, 0.1);
        border-radius: 10px; padding: 10px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
</style>
""", unsafe_allow_html=True)

# --- HELPER FUNCTIONS ---
def format_size(size_bytes):
    if not size_bytes or size_bytes == 0: return "0 B"
    size_bytes = float(size_bytes)
    for unit in['B', 'KB', 'MB', 'GB', 'TB']:
        if size_bytes < 1024.0: return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0

def create_magnet(info_hash, name):
    encoded_name = urllib.parse.quote(name)
    trackers =[
        "udp://tracker.opentrackr.org:1337/announce",
        "udp://open.demonii.com:1337/announce",
        "udp://tracker.torrent.eu.org:451/announce"
    ]
    tr_string = "".join([f"&tr={urllib.parse.quote(t)}" for t in trackers])
    return f"magnet:?xt=urn:btih:{info_hash}&dn={encoded_name}{tr_string}"

# --- API FETCHERS ---
@st.cache_data(ttl=600, show_spinner=False)
def fetch_general_torrents(query):
    """Fetches general torrents from Apibay (ThePirateBay DB)"""
    url = f"https://apibay.org/q.php?q={urllib.parse.quote(query)}"
    try:
        response = requests.get(url, timeout=10).json()
        if response and response[0].get('id') == '0': return [] # Apibay empty response
        
        results =[]
        for t in response:
            results.append({
                'id': t['info_hash'], 'name': t['name'],
                'size_bytes': int(t['size']), 'seeders': int(t['seeders']),
                'leechers': int(t['leechers']), 'uploader': t['username'],
                'date': datetime.fromtimestamp(int(t['added'])).strftime('%Y-%m-%d'),
                'magnet': create_magnet(t['info_hash'], t['name']),
                'poster': None, 'engine': 'General DB'
            })
        return results
    except Exception as e:
        return[]

@st.cache_data(ttl=600, show_spinner=False)
def fetch_movie_torrents(query):
    """Fetches Movies with Thumbnails/Images from YTS API"""
    url = f"https://yts.mx/api/v2/list_movies.json?query_term={urllib.parse.quote(query)}&limit=15"
    try:
        data = requests.get(url, timeout=10).json()
        movies = data.get('data', {}).get('movies',[])
        results = []
        for m in movies:
            for t in m.get('torrents',[]):
                results.append({
                    'id': t['hash'], 'name': f"{m['title']} ({m['year']}) [{t['quality']}]",
                    'size_bytes': t['size_bytes'], 'seeders': t['seeds'],
                    'leechers': t['peers'], 'uploader': 'YTS',
                    'date': t['date_uploaded'][:10],
                    'magnet': create_magnet(t['hash'], m['title']),
                    'poster': m['medium_cover_image'], 'engine': 'YTS Movies'
                })
        return results
    except Exception as e:
        return[]

# Advanced Feature: Streamlit Fragment to load files dynamically without resetting the whole page app state
@st.fragment
def inspect_files_fragment(info_hash):
    if st.button("📂 Inspect Torrent Contents", key=f"btn_{info_hash}"):
        with st.spinner("Fetching internal file list..."):
            try:
                files_url = f"https://apibay.org/f.php?id={info_hash}"
                f_data = requests.get(files_url, timeout=5).json()
                if f_data and isinstance(f_data, list) and 'name' in f_data[0]:
                    df = pd.DataFrame(f_data)
                    df['size'] = df['size'].apply(lambda x: format_size(x['size'][0]) if isinstance(x, dict) else format_size(x))
                    st.success(f"Found {len(df)} files inside this torrent!")
                    st.dataframe(df[['name', 'size']], use_container_width=True, hide_index=True)
                else:
                    st.warning("No file details available for this torrent.")
            except:
                st.error("Failed to connect to file tracker.")

# --- MAIN UI LAYOUT ---
st.markdown('<div class="title-anim">🌀 TorrentX Nexus</div>', unsafe_allow_html=True)
st.markdown("<p style='text-align: center; color: gray;'>Advanced search engine with deep-file inspection, health metrics, and visual covers.</p>", unsafe_allow_html=True)

# Sidebar UI
with st.sidebar:
    st.header("⚙️ Search Parameters")
    engine = st.selectbox("Select Engine",["General Torrents (Apibay)", "Movies & Posters (YTS)"])
    query = st.text_input("Search Query", placeholder="e.g., Ubuntu Linux, Inception...")
    
    st.divider()
    st.header("🎛️ Sorting & Filters")
    sort_by = st.radio("Sort By",["Seeders", "Size", "Date Added"])
    sort_order = st.radio("Order",["Descending ⬇️", "Ascending ⬆️"])
    
    st.info("💡 **Pro Tip**: Use 'General Torrents' to inspect exact files inside before downloading.")

# --- SEARCH EXECUTION & SORTING ---
results =[]
if query:
    with st.spinner("Scanning the deep web trackers... 📡"):
        if engine == "General Torrents (Apibay)":
            results = fetch_general_torrents(query)
        else:
            results = fetch_movie_torrents(query)
        time.sleep(0.3) # Artificial slight delay for animation effect

    # Apply Sorting
    if results:
        reverse = True if "Descending" in sort_order else False
        if sort_by == "Seeders":
            results = sorted(results, key=lambda x: x['seeders'], reverse=reverse)
        elif sort_by == "Size":
            results = sorted(results, key=lambda x: x['size_bytes'], reverse=reverse)
        elif sort_by == "Date Added":
            results = sorted(results, key=lambda x: x['date'], reverse=reverse)

# --- RESULTS RENDERER ---
if query and not results:
    st.warning("No results found. Try a different query or change the search engine.")
elif results:
    st.success(f"🚀 Found {len(results)} heavily seeded results for '{query}'")
    
    for i, res in enumerate(results):
        with st.container():
            st.markdown("---")
            # Create a 2-column layout (Poster vs Details)
            if res['poster']:
                col1, col2 = st.columns([1, 5])
                col1.image(res['poster'], use_container_width=True)
            else:
                col1, col2 = st.columns([0.1, 5]) # minimal spacing if no poster
            
            with col2:
                st.subheader(res['name'])
                
                # Metrics Row
                m1, m2, m3, m4, m5 = st.columns(5)
                m1.metric("🟢 Seeders", res['seeders'])
                m2.metric("🔴 Leechers", res['leechers'])
                m3.metric("💾 Size", format_size(res['size_bytes']))
                m4.metric("📅 Added", res['date'])
                m5.metric("👤 Uploader", res['uploader'])
                
                # Swarm Health Bar (Advanced Feature)
                total_peers = res['seeders'] + res['leechers']
                health = (res['seeders'] / total_peers) if total_peers > 0 else 0
                st.caption(f"Swarm Health: {int(health * 100)}%")
                st.progress(health)

                # Action Buttons inside Expander
                with st.expander("🛠️ View Tools, Magnet & File Contents"):
                    st.markdown("#### 🧲 Magnet Link (1-Click Copy)")
                    # Streamlit natively places a Copy icon inside st.code blocks!
                    st.code(res['magnet'], language='http')
                    
                    c1, c2 = st.columns(2)
                    with c1:
                        st.markdown(f"**[⬇️ Download .torrent File](https://itorrents.org/torrent/{res['id']}.torrent)**")
                    with c2:
                        # Only General DB supports dynamic deep-file checking via APIbay currently
                        if res['engine'] == 'General DB':
                            inspect_files_fragment(res['id'])
                        else:
                            st.info("File inspection locked. (YTS batches files).")
else:
    # Empty State Beautiful UI
    st.markdown("<br><br><br>", unsafe_allow_html=True)
    c1, c2, c3 = st.columns([1, 2, 1])
    with c2:
        st.info("👈 **Start by typing your search in the sidebar.** \n\n *Explore high-definition movie thumbnails or dive deep into software file contents using our dual-engine setup.*")
